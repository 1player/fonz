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

private def list_command()
  installed_fonts = LocalDatabase.instance.installed_fonts

  if installed_fonts.size < 1
    puts "No fonts installed."
    return
  end

  printf "%-40s\t%10s\n", "name", "version"
  installed_fonts.each do |font|
    printf "%-40s\t%10s\n", font.name, font.version
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
  parser.on("list", "List installed fonts") do
    parser.banner = "usage: font list\n"
    list_command()
    exit 1
  end
  parser.unknown_args do |args, _|
    STDERR.puts parser
    exit 1
  end
end
