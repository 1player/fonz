require "http/client"
require "json"

abstract class Source
  include YAML::Serializable
  use_yaml_discriminator "type", {
    "github-release": GithubReleaseSource,
  }

  getter type : String

  abstract def latest_release()
end

class GithubAPI
  def initialize()
    @client = HTTP::Client.new "api.github.com", tls: true
  end

  def get(url)
    resp = @client.get url, headers: HTTP::Headers{"Accept" => "application/vnd.github.v3+json"}
    resp.body?.try do |body|
      JSON.parse(body)
    end
  end

  def latest_release(repo)
    get "/repos/#{repo}/releases/latest"
  end
end

class GithubReleaseSource < Source
  property repo : String
  property asset : String?

  def tag_name_to_version(name)
    name.lchop("v")
  end

  def asset_name(version)
    if (asset = @asset)
      asset.sub("$VERSION", version)
    else
      raise "Unimplemented"
    end
  end

  def latest_release() : {String, String}
    data = GithubAPI.new.latest_release(repo).not_nil!

    version = tag_name_to_version(data["tag_name"].to_s)

    download_url = if @asset
                     # Download a specific asset
                     asset_name = asset_name(version)
                     data["assets"]
                       .as_a
                       .find { |asset| asset.as_h["name"] == asset_name }
                       .try { |asset| asset.as_h["browser_download_url"].as_s }
                   else
                     # Download tarball
                     data["tarball_url"].as_s
                   end

    {download_url.not_nil!, version}
  end
end
