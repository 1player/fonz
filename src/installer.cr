require "file_utils"
require "./recipe"
require "./utils"

class Installer
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
      download_path = Utils.download_file(download_url, temp_dir).not_nil!
      #puts "Saved as #{download_path}"

      # 2. Unpack
      puts "Unpacking #{download_path}..."
      Utils.unpack(download_path, temp_dir)

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
      fonts_dir = Path["~/.local/share/fonts"].expand(home: true)
      dest_dir = Path.new(fonts_dir, "fancy", recipe.name)
      Dir.mkdir_p(dest_dir)

      font_files.each do |file|
        path = Path.new(file).relative_to?(temp_dir).not_nil!
        dir_component = path.dirname
        if dir_component
          Dir.mkdir_p(Path.new(dest_dir, dir_component))
        end
        dest_path = Path.new(dest_dir, path)

        puts "Installing #{dest_path}..."
        File.copy(file, dest_path)
      end
    end
  end
end
