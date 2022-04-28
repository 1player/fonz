require "http/client"
require "mime"

MIME.init()

module Utils
  extend self

  def filename_from_content_disposition(cd)
    if cd =~ /^attachment; filename=(.*)$/i
      $~[1]
    end
  end

  def download_file(url, dir = Dir.tempdir)
    HTTP::Client.get(url) do |resp|
      if resp.status_code == 302 && (location = resp.headers["Location"]?)
        return download_file(location, dir)
      end

      if resp.success?
        filename = if (cd = resp.headers["Content-Disposition"]?)
                     filename_from_content_disposition(cd)
                   elsif (ct = resp.headers["Content-Type"]?)
                     suffix = MIME.extensions(ct)
                              .first?
                              .try { |ext| ".#{ext}" }
                     File.tempname(nil, suffix, dir: "")
                   end

        filename = File.tempname(dir: "") unless filename

        path = Path.new(dir, filename)
        File.open(path, "wb") do |f|
          IO.copy(resp.body_io, f)
        end

        path
      end
    end
  end
end
