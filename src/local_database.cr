require "yaml"
require "./utils"

DATABASE_VERSION = 20220912_u32

class InstalledFont
  include YAML::Serializable

  property name : String
  property version : String

  def initialize(name : String, version : String)
    @name = name
    @version = version
  end
end

class Database
  include YAML::Serializable

  property database_version : UInt32
  property installed_fonts : Array(InstalledFont)

  def initialize()
    @database_version = DATABASE_VERSION
    @installed_fonts = [] of InstalledFont
  end
end

class LocalDatabase
  @data : Database

  def self.instance
    @@instance ||= new
  end

  private def initialize
    if File.exists?(path)
      @data = File.open(path) do |file|
        Database.from_yaml(file)
      end
    else
      @data = Database.new()
      save
    end
  end

  def path
    Path.new(Utils.data_directory, "database.yml")
  end

  def save
    File.open(path, "w") do |f|
      @data.to_yaml(f)
    end
  end

  def mark_font_as_installed(font : InstalledFont)
    @data.installed_fonts << font

    save
  end

  def font_installed?(name)
    @data.installed_fonts.any?{ |font| font.name == name }
  end

  def installed_version(name)
    font = @data.installed_fonts.find { |font| font.name == name }
    font.version || nil
  end

  def installed_fonts()
    @data.installed_fonts
  end
end
