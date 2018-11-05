require "time" # will be required by time_util, but lets be explicit for now
require "option_parser"

require "../print"
require "../repo"
require "../time_util"
require "../status"
require "../task"

def cmd_add_task (args)
    task = Task.new status: Status::Upcoming
    schedule = nil

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
        "-s STATUS", "--status=TAG", "Status of the task"
    ) { |v| task.status = Status.parse v }

    parser.on(
        "-d DELAY", "--delay=DELAY", "Delay the task until a certain time"
    ) { |v| task.delay_until = Time.utc_now >> v }

    parser.on(
        "--schedule=SCHEDULE", "Schedule a recurring task"
    ) { |v| task.schedule = v }

    parser.unknown_args { |v| task.name = v.join " " }
    parser.parse(args)

    if task.name == ""
        puts parser.to_s
        exit(1)
    end

    created_task = Repo.create_task(task)
    Scheduling.update_schedule task
    print_task created_task
end
