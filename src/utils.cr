require "http/client"

module Utils
  def self.data_directory
    Path.new(xdg_data_home(), "fonz")
  end

  def self.user_fonts_directory
    Path.new(xdg_data_home(), "fonts")
  end

  private def self.filename_from_content_disposition(cd)
    if cd =~ /^attachment; filename=(.*)$/i
      $~[1]
    end
  end

  def self.download_file(url, dir, filename = nil)
    HTTP::Client.get(url) do |resp|
      if resp.status_code == 302 && (location = resp.headers["Location"]?)
        return download_file(location, dir)
      end

      if resp.success?
        filename ||= if (cd = resp.headers["Content-Disposition"]?)
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

        path.to_s
      end
    end
  end

  # https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html

  def self.xdg_config_home : String
    ENV["XDG_CONFIG_HOME"]? || Path["~/.config"].expand(home: true).to_s
  end

  def self.xdg_data_home : String
    ENV["XDG_DATA_HOME"]? || Path["~/.local/share"].expand(home: true).to_s
  end
end
