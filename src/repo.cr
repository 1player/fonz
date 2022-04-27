require "./recipe"

REPO_PATH = "example-repo.yml"

private def fuzzy_name_matches?(name, query)
  name.downcase.includes?(query.downcase)
end

class Repo
  def initialize
    @path = REPO_PATH
    @recipes = [] of Recipe
    load()
  end

  def load
    @recipes = File.open(@path) do |file|
      Array(Recipe).from_yaml(file)
    end
  end

  def search(query)
    @recipes
      .select { |recipe| fuzzy_name_matches?(recipe.name, query) }
      .sort { |a, b| a.name <=> b.name }
  end

  def find_one_exact(name)
    match = @recipes.select do |recipe|
      name.downcase == recipe.name.downcase
    end
    if match.size == 1
      match[0]
    else
      nil
    end
  end
end
