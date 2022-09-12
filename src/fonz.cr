require "option_parser"
require "yaml"
require "./installer"
require "./repo"

private def install_command(name, *, dry_run = false)
  recipe =
    if name =~ %r(/)
      if File.exists?(name)
        File.open(name) do |file|
          Recipe.from_yaml(file)
        end
      else
        puts "#{name}: No such file or directory."
        exit 1
      end
    else
      if match = Repo.new.find_one_exact(name)
        match
      else
        puts "No font named '#{name}' found."
        exit 1
      end
    end

  Installer.new.install(recipe, dry_run: dry_run)
end

private def search_command(query)
  repo = Repo.new

  matches = repo.search(query)
  if matches.size == 0
    puts "No font matching '#{query}' found."
    exit 1
  else
    matches.each_with_index 1 do |recipe, i|
      puts "#{recipe.name}"
    end
  end
end

##

OptionParser.parse() do |parser|
  parser.banner = "usage: fonz <command>\n"
  parser.on("-h", "--help", "Show this help") do
    STDERR.puts parser
    exit 1
  end
  parser.on("--refresh", "Force update of the font repository") do
    Repo.refresh
  end
  parser.on("install", "Install a font") do
    dry_run = false
    parser.banner = <<-EOF
    usage:
      fonz install <font name> [options]   - Install a font by name
      OR
      fonz install <recipe.yaml> [options] - Install a font from YAML recipe

    EOF
    parser.on("-n", "--dry-run", "Perform trial installation with no changes made") do
      dry_run = true
    end
    parser.unknown_args do |args, _|
      if args.size > 0
        name = args[0..].join(" ")
        install_command(name, dry_run: dry_run)
      else
        STDERR.puts parser
        exit 1
      end
    end
  end
  parser.on("search", "Search a font by name") do
    parser.banner = "usage: fonz search <query> [options]\n"
    parser.unknown_args do |args, _|
      if args.size > 0
        query = args[0..].join(" ")
        search_command(query)
      else
        STDERR.puts parser
        exit 1
      end
    end
  end
  parser.unknown_args do |args, _|
    STDERR.puts parser
    exit 1
  end
end
