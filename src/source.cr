abstract class Source
  include YAML::Serializable
  use_yaml_discriminator "type", {
    "github-release": GithubReleaseSource,
  }

  getter type : String
end

class GithubReleaseSource < Source
  property repo : String
  property asset : String?
end
