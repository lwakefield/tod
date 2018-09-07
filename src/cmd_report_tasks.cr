require "option_parser"
require "json"

require "./db"
require "./status"
require "./print"
require "./task"
require "./time_util"

class Command
    def self.report_tasks (args)
        modified_after = nil
        modified_before = nil

        OptionParser.parse args do |parser|
            parser.banner = "Usage: list [arguments]"
            parser.unknown_args do |args|
                if args.size == 0
                    puts parser.to_s
                    exit(1)
                end

                arg = args.join(" ").gsub(/[_\- ]/, " ")
                if arg == "today"
                    modified_after = Time.now.at_beginning_of_day
                    modified_before = modified_after.as(Time).at_end_of_day
                elsif arg == "yesterday"
                    modified_after = (Time.now - 1.day).at_beginning_of_day
                    modified_before = modified_after.as(Time).at_end_of_day
                elsif arg == "lastweek"
                    modified_after = (Time.now.at_beginning_of_week - 1.day).at_beginning_of_week
                    modified_before = modified_after.as(Time).at_end_of_week
                elsif arg == "thisweek"
                    modified_after = (Time.now.at_beginning_of_week).at_beginning_of_week
                    modified_before = modified_after.as(Time).at_end_of_week
                end
            end
        end

        prepared_vals = {
            modified_after.as(Time),
            modified_before.as(Time),
        }

        tasks = DeprecatedTask.from_rs DATABASE.query(
            "select * from tasks where modified_at between ? and ?",
            *prepared_vals
        )
        tasks.concat DeprecatedTask.from_rs DATABASE.query(
            "select * from tasks_history where modified_at between ? and ?",
            *prepared_vals
        )

        tasks.sort! { |a,b| b.modified_at.as(Time) <=> a.modified_at.as(Time) }
        tasks.uniq! &.id

        print_tasks tasks
    end
end
