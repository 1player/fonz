require "./source"
require "./utils"

class Recipe
  include YAML::Serializable

  property name : String
  property format : String?
  property script : String?
  property source : Source

  def install
    # 1. Create temporary directory
    temp_dir = File.tempname()
    Dir.mkdir(temp_dir)

    # 2. Download file
    download_url = @source.download_url().not_nil!
    puts "Downloading #{download_url} ..."
    download_path = Utils.download_file(download_url, temp_dir).not_nil!
    puts "Saved as #{download_path}"

    # 3. Unpack
    # 4. Run script
    # 5. Collect files
  end
end
