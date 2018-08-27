require "json"
require "colorize"

COLUMNS = [
    "id",
    "age",
    "name",
    "tags",
    "urgency",
    "importance",
    "priority",
    "status",
]

def print_tasks (tasks)
    # Work out the size for each column
    longest_strings = { } of String => Int32
    COLUMNS.each { |v| longest_strings[v] = v.size }

    tasks.each do |task|
        COLUMNS.each do |prop|
            prop_val = task.fetch(prop).to_s
            if prop_val.size > longest_strings[prop]
                longest_strings[prop] = prop_val.size
            end
        end
    end

    # Print the headers
    headers = COLUMNS.map { |v| v.ljust(longest_strings[v]) }.join " "
    headers = headers.colorize.bold if STDOUT.tty?
    puts headers

    # Print the tasks
    tasks.each do |task|
        row = COLUMNS.map { |v| task.fetch(v).to_s.ljust(longest_strings[v]) }.join " "
        puts row
    end
end
