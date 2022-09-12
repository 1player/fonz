require "file_utils"
require "http/client"
require "mime"
require "process"
require "./recipe"
require "./utils"
require "./local_database"

# MIME.init()

class Installer
  enum ArchiveType
    Tarball
    Zip
  end

  def archive_type(filename)
    if filename =~ /\.zip$/
      ArchiveType::Zip
    elsif filename =~ /\.tar.\w+$/ || filename =~ /\.tgz$/
      ArchiveType::Tarball
    else
      raise "#{filename}: unknown archive type"
    end
  end

  def unpack(file, dir)
    p =
      case archive_type(file)
      in ArchiveType::Zip
        unpack_zip(file, dir)
      in ArchiveType::Tarball
        unpack_tarball(file, dir)
      end

    unless p.success?
      raise "Unpacking #{file} failed with status code ${p.exit_status}"
    end
  end

  def unpack_zip(file, dir)
    Process.run("unzip", [ "-d", dir, file ])
  end

  def unpack_tarball(file, dir)
    Process.run("tar", [ "-C", dir, "-xf", file ])
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

  def run_script(script, directory)
    p = Process.run(script, shell: true, chdir: directory)
    unless p.success?
      raise "Installation script failed with status code: #{p.exit_status}"
    end
  end

  def install(recipe : Recipe, *, dry_run = false)
    # Abort if font is already installed
    if LocalDatabase.instance.font_installed?(recipe.name)
      puts "#{recipe.name} is already installed."
      return
    end
    
    with_tempdir do |temp_dir|
      # 1. Download file
      download_url, version = recipe.source.latest_release()
      puts "Installing #{recipe.name} version #{version}..."
      puts "Downloading #{download_url} ..."
      download_path = Utils.download_file(download_url, temp_dir).not_nil!

      # 2. Unpack
      puts "Unpacking #{download_path}..."
      unpack(download_path, temp_dir)

      # 3. Run script
      if script = recipe.script
        run_script(script, temp_dir)
      end

      # 4. Collect files
      font_files = Dir.glob(format_glob(recipe.format, temp_dir))

      if font_files.size == 0
        puts "No matching font file found."
        return
      end

      # 5. Install files
      dest_dir = Path.new(Utils.user_fonts_directory, recipe.name)
      Dir.mkdir_p(dest_dir) unless dry_run

      font_files.each do |file|
        path = Path.new(file)
        dest_path = Path.new(dest_dir, path.basename)

        puts "Installing #{dest_path}..."
        FileUtils.mv(file, dest_path) unless dry_run
      end

      # Update local database
      unless dry_run
        font = InstalledFont.new(recipe.name, version)
        LocalDatabase.instance.mark_font_as_installed(font)
      end
    end
  end
end
