require "http/client"
require "mime"
require "process"

MIME.init()

module Utils
  extend self

  enum ArchiveType
    #Tarball
    Zip
  end

  def filename_from_content_disposition(cd)
    if cd =~ /^attachment; filename=(.*)$/i
      $~[1]
    end
  end

  def archive_type(filename)
    # if filename =~ /\.tar\.\w+$/
    #   ArchiveType::Tarball
    # elsif MIME.from_filename(filename) == "application/zip"
    #   ArchiveType::Zip
    # else
    #   raise "#{filename}: unknown archive type"
    # end

    if MIME.from_filename(filename) == "application/zip"
      ArchiveType::Zip
    else
      raise "#{filename}: unknown archive type"
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

        path.to_s
      end
    end
  end

  def unpack(file, dir)
    case archive_type(file)
    in ArchiveType::Zip
      unpack_zip(file, dir)
    end
  end

  def unpack_zip(file, dir)
    p = Process.run("unzip", [ "-d", dir, file ])
    unless p.success?
      raise "Unpacking #{file} failed with status code ${p.exit_status}"
    end
  end
end
