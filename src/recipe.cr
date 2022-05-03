require "./source"
require "./utils"

class Recipe
  include YAML::Serializable

  property name : String
  property format : String
  property script : String?
  property source : Source

  def format_glob(dir)
    Path.new(dir, "**", "*.#{@format}")
  end

  def install
    # 1. Create temporary directory
    temp_dir = File.tempname()
    Dir.mkdir(temp_dir)

    # 2. Download file
    download_url = @source.download_url().not_nil!
    puts "Downloading #{download_url} ..."
    download_path = Utils.download_file(download_url, temp_dir).not_nil!
    #puts "Saved as #{download_path}"

    # 3. Unpack
    puts "Unpacking #{download_path}..."
    Utils.unpack(download_path, temp_dir)

    # 4. Run script
    if script
      raise "Script execution not implemented yet."
    end

    # 5. Collect files
    font_files = Dir.glob(format_glob(temp_dir))

    if font_files.size == 0
      puts "No matching font file found."
      return
    end

    fonts_dir = Path["~/.local/share/fonts"].expand(home: true)
    dest_dir = Path.new(fonts_dir, "fancy", @name)
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
