require "option_parser"
require "json"

require "./db"
require "./status"
require "./print"

# TODO: refactor this
class Command
    def self.list_tasks (args)
        tags = [] of String
        status = nil
        all = false

        OptionParser.parse args do |parser|
            parser.banner = "Usage: list [arguments]"
            parser.on("-t TAG", "--tag=TAG", "Filter against tags") { |v| tags << v }
            parser.on("-s STATUS", "--status=STATUS", "Filter against status") { |v| status = Status.parse(v).to_i }
            parser.on("-a", "--all", "Show all tasks regardless of status") { all = true }
        end

        # TODO list a single task

        # prepare the query
        vals = [] of String
        conditions = [] of String

        unless all
            conditions << "status not in (#{Status::Deleted.to_i}, #{Status::Completed.to_i})"
            conditions << "(delay_until is null or delay_until < date('now', 'utc'))"
        end
        if tags.size > 0
            conditions.concat tags.map { |v| "tags like ?"}
            vals.concat tags.map { |v| "%\"#{v}\"%" }
        end

        unless status.nil?
            conditions << "status = ?"
            vals << status.to_s
        end

        where_clause = "where " + conditions.join " and " if conditions.size > 0

        q = <<-QUERY
            select * from tasks
            #{ where_clause unless where_clause.nil?}
        QUERY

        tasks = Task.from_rs DATABASE.query(q, vals)
        tasks = tasks.sort { |a, b| b.priority <=> a.priority }
        if tasks.size == 0
            puts "No tasks remaining!"
            exit(0)
        end

        print_tasks tasks
    end
end
