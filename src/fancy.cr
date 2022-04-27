require "option_parser"
require "yaml"
require "./repo"

private def read_index_choice : UInt32?
  printf "Confirm choice: "
  n = (gets || "").to_u32?
  n && n < 1 ? nil : n
end

private def search_command(query)
  repo = Repo.new

  matches = repo.search(query)
  if matches.size == 0
    puts "No font matching '#{query}' found."
    exit 1
  else
    matches.each_with_index 1 do |recipe, i|
      puts "##{i}: #{recipe.name}"
    end
    if (i = read_index_choice()) && (recipe = matches[i - 1]?)
      recipe.install
    end
  end
end


OptionParser.parse() do |parser|
  parser.banner = "usage: fancy <command>"
  parser.on("-h", "--help", "Show this help") do
    STDERR.puts parser
    exit 1
  end
  parser.on("search", "Search a font by name") do
    parser.banner = "usage: fancy search <query> [options]"
    # opts = {:refresh => false}
    # parser.on("--refresh", "Force repository refresh") do
    #   opts[:refresh] = true
    # end
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
