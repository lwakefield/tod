require "option_parser"
require "json"

require "./repo"
require "./status"

class Command
    def self.update_task (args)

        task = {
            "tags" => [] of String
        } of String => String | Array(String) | Int32
        remove_tags = [] of String

        OptionParser.parse args do |parser|
            parser.banner = "Usage: add [flags] <id> <name>"
            parser.on("-u URGENCY", "--urgency=URGENCY", "Urgency of task") { |v| task["urgency"] = v }
            parser.on("-i IMPORTANCE", "--importance=IMPORTANCE", "Importance of task") { |v| task["importance"] = v }
            parser.on("-s STATUS", "--status=STATUS", "Status of task") { |v| task["status"] = Status.parse(v).to_i }
            parser.on("-t TAG", "--tag=TAG", "Tag the task") { |v| task["tags"].as(Array) << v }
            parser.on("-T TAG", "--remove-tag=TAG", "Remove a tag from the task") { |v| remove_tags << v }
            parser.unknown_args do |v|
                if v.size == 0
                    puts parser.to_s && exit(1)
                    exit(1)
                end

                task["id"] = v.first
                task["name"] = v[1..-1].join " " unless v.size == 1
            end
        end

        if task.has_key?("tags")
            id = task["id"]
            existing_tags = Array(String).from_json(
                DATABASE.query_one("select tags from tasks where id=?", id, as: {String})
            )
            task["tags"] = existing_tags | task["tags"].as(Array)
        end

        if remove_tags.size > 0
            task["tags"] = task["tags"].as(Array) - remove_tags
        end

        Repo.update_task(task)
    end
end

