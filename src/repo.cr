require "time"
require "./recipe"
require "./utils"

REPO_URL = "https://raw.githubusercontent.com/1player/fonz-repo/master/repo.yml"
REPO_FILENAME = "repo.yml"
REPO_PATH = Path.new(Utils.data_directory, REPO_FILENAME)

MAX_REPO_AGE_BEFORE_REFRESH = Time::Span.new(days: 1)

private def fuzzy_name_matches?(name, query)
  name.downcase.includes?(query.downcase)
end

class Repo
  def initialize
    @recipes = [] of Recipe
    Repo.refresh_if_needed
    load()
  end

  def self.refresh_if_needed
    if info = File.info?(REPO_PATH)
      self.refresh if Time.local > (info.modification_time + MAX_REPO_AGE_BEFORE_REFRESH)
    else
      self.refresh
    end
  end

  def self.refresh
    puts "Refreshing font repository..."
    Dir.mkdir_p(Utils.data_directory)
    Utils.download_file(REPO_URL, Utils.data_directory, REPO_FILENAME).not_nil!
  end

  def load
    @recipes = File.open(REPO_PATH) do |file|
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
