require "option_parser"
require "json"

require "./db"
require "./status"
require "./print"

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

        # prepare the query
        vals = [] of String
        conditions = [] of String

        conditions << "status not in (#{Status::Deleted.to_i}, #{Status::Completed.to_i})" unless all || status
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
            select
                id,
                (date('now') - created_at) || 'd' as age,
                name,
                tags,
                urgency as u,
                importance as i,
                urgency + importance as p,
                case status
                    #{ Status.values.map { |v| "when #{v.value} then '#{v.to_s.downcase}'"}.join " " }
                end status
            from tasks
            #{ where_clause unless where_clause.nil?}
            order by p desc
        QUERY

        tasks = DATABASE.query(q, vals).to_array
        if tasks.size == 0
            puts "No tasks remaining!"
            exit(0)
        end

        print_tasks tasks
    end
end
