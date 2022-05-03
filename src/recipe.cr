require "./source"

class Recipe
  include YAML::Serializable

  property name : String
  property format : String
  property script : String?
  property source : Source
end
