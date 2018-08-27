require "option_parser"
require "json"

require "./repo"
require "./status"
require "./time_util"

class Command
    def self.update_task (args)
        urgency = nil
        importance  = nil
        status = nil
        tags_to_add = [] of String
        tags_to_remove = [] of String
        delay_until = nil
        id = nil
        name = nil

        OptionParser.parse args do |parser|
            parser.banner = "Usage: add [flags] <id> <name>"
            parser.on("-u URGENCY", "--urgency=URGENCY", "Urgency of task") { |v| urgency = v.to_i }
            parser.on("-i IMPORTANCE", "--importance=IMPORTANCE", "Importance of task") { |v| importance = v.to_i }
            parser.on("-s STATUS", "--status=STATUS", "Status of task") { |v| status = Status.parse(v) }
            parser.on("-t TAG", "--tag=TAG", "Tag the task") { |v| tags_to_add.as(Array) << v }
            parser.on("-T TAG", "--remove-tag=TAG", "Remove a tag from the task") { |v| tags_to_remove << v }
            parser.on(
                "-d DELAY", "--delay=DELAY", "Delay the task until a certain time"
            ) { |v| delay_until = Time.utc_now >> v }
            parser.unknown_args do |v|
                if v.size == 0
                    puts parser.to_s && exit(1)
                    exit(1)
                end

                id = v.first.to_i64
                name = v[1..-1].join " " unless v.size == 1
            end
        end

        task_to_update             = Repo.get_task(id)
        task_to_update.urgency     = urgency.as(Int32) unless urgency.nil?
        task_to_update.importance  = importance.as(Int32) unless importance.nil?
        task_to_update.name        = name.as(String) unless name.nil?
        task_to_update.status      = status.as(Status) unless status.nil?
        task_to_update.delay_until = delay_until.as(Time) unless delay_until.nil?
        task_to_update.tags        = (task_to_update.tags | tags_to_add) - tags_to_remove

        Repo.update_task(task_to_update)
    end
end

