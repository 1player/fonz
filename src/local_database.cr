require "yaml"
require "./utils"

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

  property installed_fonts : Array(InstalledFont)

  def initialize()
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

  def mark_font_as_installed(name, version)
    @data.installed_fonts << InstalledFont.new(name, version)

    save
  end
end
