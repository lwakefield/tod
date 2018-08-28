require "./db"
require "./cmd_add_task"
require "./cmd_list_tasks"
require "./cmd_delete_tasks"
require "./cmd_update_task"
require "./cmd_detail_task"

migrate_db

if ARGV.size == 0
    Command.list_tasks([] of String)
    exit()
end

case ARGV[0]
when "a", "add"
    Command.add_task2(ARGV[1..-1])
when "l", "list"
    Command.list_tasks(ARGV[1..-1])
when "u", "update"
    Command.update_task(ARGV[1..-1])
when "delete"
    Command.delete_tasks(ARGV[1..-1])
when "detail"
    Command.detail_task(ARGV[1..-1])
when "done", "complete", "finish"
    Command.update_task(ARGV[1..-1] + ["--status=completed"])
when "start", "begin"
    Command.update_task(ARGV[1..-1] + ["--status=started"])
else
end
