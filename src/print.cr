require "json"
require "colorize"

def print_tasks (_tasks)
    tasks = _tasks.clone
    tasks.each do |task|
        if task.has_key? "tags"
            tags = Array(String).from_json task["tags"]
            task["tags"] = tags.join ","
        end
    end

    column_names = tasks.first.keys

    # Work out the size for each column
    longest_strings = {} of String => Int32
    column_names.each { |v| longest_strings[v] = v.size}

    tasks.each do |task|
        task.each do |k, v|
            if v.size > longest_strings[k]
                longest_strings[k]=v.size
            end
        end
    end
    longest_strings.each { |k, v| longest_strings[k] = v }

    # Print the headers
    headers = column_names.map { |v| v.ljust(longest_strings[v]) }.join " "
    headers = headers.colorize.bold if STDOUT.tty?
    puts headers

    # # Print the tasks
    tasks.each_with_index do |task, i|
        row = column_names.map { |v| task[v].ljust(longest_strings[v]) }.join " "
        puts row
    end
end
