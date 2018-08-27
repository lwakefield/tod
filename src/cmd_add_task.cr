require "time" # will be required by time_util, but lets be explicit for now
require "option_parser"

require "./repo"
require "./time_util"
require "./status"
require "./Task"

class Command
    def self.add_task2 (args)
        task = Task.new status: Status::Upcoming

        parser = OptionParser.new do |p|
            p.banner = "Usage: add [task name]"

            p.on(
                "-u URGENCY", "--urgency=URGENCY", "Urgency of task"
            ) { |v| task.urgency = v.to_i }

            p.on(
                "-i IMPORTANCE", "--importance=IMPORTANCE", "Importance of task"
            ) { |v| task.importance = v.to_i }

            p.on(
                "-t TAG", "--tag=TAG", "Tag the task"
            ) { |v| task.tags << v }

            p.on(
                "-d DELAY", "--delay=DELAY", "Delay the task until a certain time"
            ) { |v| task.delay_until = Time.utc_now >> v }

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
