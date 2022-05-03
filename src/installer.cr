require "file_utils"
require "http/client"
require "mime"
require "process"
require "./recipe"
require "./utils"

MIME.init()

class Installer
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

  def format_glob(format : String, dir)
    Path.new(dir, "**", "*.#{format}")
  end

  def with_tempdir(&block: String -> _)
    tempdir = File.tempname()
    Dir.mkdir(tempdir)

    begin
      yield tempdir
    ensure
      FileUtils.rm_rf(tempdir)
    end
  end

  def install(recipe : Recipe)
    with_tempdir do |temp_dir|
      # 1. Download file
      download_url = recipe.source.download_url().not_nil!
      puts "Downloading #{download_url} ..."
      download_path = download_file(download_url, temp_dir).not_nil!
      #puts "Saved as #{download_path}"

      # 2. Unpack
      puts "Unpacking #{download_path}..."
      unpack(download_path, temp_dir)

      # 3. Run script
      if recipe.script
        raise "Script execution not implemented yet."
      end

      # 4. Collect files
      font_files = Dir.glob(format_glob(recipe.format, temp_dir))

      if font_files.size == 0
        puts "No matching font file found."
        return
      end

      # 5. Install files
      dest_dir = Path.new(Utils.user_fonts_directory, "fancy", recipe.name)
      Dir.mkdir_p(dest_dir)

      font_files.each do |file|
        path = Path.new(file).relative_to?(temp_dir).not_nil!
        dir_component = path.dirname
        if dir_component
          Dir.mkdir_p(Path.new(dest_dir, dir_component))
        end
        dest_path = Path.new(dest_dir, path)

        puts "Installing #{dest_path}..."
        FileUtils.mv(file, dest_path)
      end
    end
  end
end
