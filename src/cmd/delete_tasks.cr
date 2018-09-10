require "option_parser"

require "../repo"

def cmd_delete_tasks (args)
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

    tasks = Repo.get_tasks(task_ids)
    tasks.each do |t|
        t.status = Status::Deleted
        Repo.update_task (t)
    end
end
