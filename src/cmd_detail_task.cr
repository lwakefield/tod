require "option_parser"
require "json"

require "./print"
require "./repo"

class Command
    def self.detail_task (args)
        task_id = nil

        parser = OptionParser.new
        parser.banner = "Usage: detail [id]"
        parser.unknown_args do |v|
            if v.size == 0
                puts parser.to_s && exit(1)
                exit(1)
            end

            task_id = v.first.to_i64
        end
        parser.parse args

        task = Repo.get_task task_id

        print_task task
    end
end
