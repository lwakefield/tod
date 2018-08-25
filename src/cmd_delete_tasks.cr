require "option_parser"

require "./repo"

class Command
    def self.delete_tasks (args)
        task_ids = [] of String
        OptionParser.parse args do |parser|
            parser.banner = "Usage: delete [arguments]"
            parser.unknown_args do |v|
                if v.size == 0
                    puts parser.to_s && exit(1)
                    exit(1)
                end

                task_ids = v
            end
        end

        task_ids.each { |id| Repo.update_task({ "id" => id, "status" => Status::Deleted.to_i }) }
    end
end
