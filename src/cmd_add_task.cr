require "time" # will be required by time_util, but lets be explicit for now
require "option_parser"

require "./repo"
require "./time_util"
require "./status"

class Command
    def self.add_task2 (args)
        task = Task.new status: Status::Upcoming

        parser = OptionParser.new do |p|
            p.banner = "Usage: add [task name]"
            p.on( "-u URGENCY", "--urgency=URGENCY", "Urgency of task") do |v|
                task.urgency = v.to_i
            end
            p.on("-i IMPORTANCE", "--importance=IMPORTANCE", "Importance of task") do |v|
                task.importance = v.to_i
            end
            p.on("-t TAG", "--tag=TAG", "Tag the task") do |v|
                task.tags << v
            end
            # # TODO finish this
            p.on "-d DELAY", "--delay=DELAY", "Delay the task until" do |v|
                task.delay_until = Time.utc_now >> v
            end
            p.unknown_args { |v| task.name = v.join " " }
        end
        parser.parse(args)

        if task.name == ""
            puts parser.to_s && exit(1)
            exit(1)
        end

        Repo.create_task(task)
        # TODO print the created_task
    end
end
