require "time" # will be required by time_util, but lets be explicit for now
require "option_parser"

require "./repo"
require "./time_util"
require "./status"
require "./Task"

class Command
    def self.add_task2 (args)
        task = Task.new status: Status::Upcoming

        parser = OptionParser.new
        parser.banner = "Usage: add [task name]"

        parser.on(
            "-u URGENCY", "--urgency=URGENCY", "Urgency of task"
        ) { |v| task.urgency = v.to_i }

        parser.on(
            "-i IMPORTANCE", "--importance=IMPORTANCE", "Importance of task"
        ) { |v| task.importance = v.to_i }

        parser.on(
            "-t TAG", "--tag=TAG", "Tag the task"
        ) { |v| task.tags << v }

        parser.on(
            "-d DELAY", "--delay=DELAY", "Delay the task until a certain time"
        ) { |v| task.delay_until = (Time.utc_now >> v).as(Time).at_beginning_of_day }

        parser.unknown_args { |v| task.name = v.join " " }
        parser.parse(args)

        if task.name == ""
            puts parser.to_s
            exit(1)
        end

        Repo.create_task(task)
        # TODO print the created_task
    end
end
