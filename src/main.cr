require "./db"
require "./cmd/*"

if ARGV.size == 0
    cmd_list_tasks([] of String)
    exit()
end

migrate_db

case ARGV[0]
when "a", "add"
    cmd_add_task(ARGV[1..-1])
when "l", "list"
    cmd_list_tasks(ARGV[1..-1])
when "started", "inprogress"
    cmd_list_tasks(ARGV[1..-1] + ["--status=started"])
when "u", "update"
    cmd_update_task(ARGV[1..-1])
when "delete"
    cmd_delete_tasks(ARGV[1..-1])
when "detail"
    cmd_detail_task(ARGV[1..-1])
when "report"
    cmd_report_tasks(ARGV[1..-1])
when "done", "complete", "finish"
    cmd_update_task(ARGV[1..-1] + ["--status=completed"])
when "start", "begin"
    cmd_update_task(ARGV[1..-1] + ["--status=started"])
else
end
