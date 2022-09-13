require "./source"

class Recipe
  include YAML::Serializable

  property name : String
  property format : String
  property script : String?
  property source : Source

  def self.deserialize(filename)
    File.open(filename) do |f|
      Recipe.from_yaml(f)
    end
  end
end
