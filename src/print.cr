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

COLS = `tput cols`.strip.to_i

def print_tasks (tasks)
    # Work out the size for each column
    longest_strings = { } of String => Int32
    COLUMNS.each { |v| longest_strings[v] = v.size }

    formatted_tasks = tasks.map &.to_h
    formatted_tasks.each do |task|
        task["tags"] = task["tags"].as(Array).join ","
    end

    formatted_tasks.each do |task|
        COLUMNS.each do |prop|
            prop_val = task[prop].to_s
            if prop_val.size > longest_strings[prop]
                longest_strings[prop] = prop_val.size
            end
        end
    end

    required_space = longest_strings.values.sum + (longest_strings.size - 1)
    available_space = `tput cols`.strip.to_i
    if STDOUT.tty? && required_space > available_space
        if available_space < 80
            longest_strings["urgency"] = 1
            longest_strings["importance"] = 1
            longest_strings["priority"] = 1
        end

        # TODO there has to be a better var name than this...
        name_max_space = available_space - (longest_strings.reject("name").values.sum + (longest_strings.size - 1))
        longest_strings["name"] = name_max_space if required_space > available_space

        formatted_tasks.each do |task|
            task["name"] = task["name"].to_s[0...(name_max_space-3)] + "..." if task["name"].as(String).size > name_max_space
        end
    end


    # Print the headers
    headers = COLUMNS.map { |v| v.ljust(longest_strings[v])[0...longest_strings[v]] }.join " "
    headers = headers.colorize.bold if STDOUT.tty?
    puts headers

    formatted_tasks.each do |task|
        row = COLUMNS.map { |v| task[v].to_s.ljust(longest_strings[v]) }.join " "
        puts row
    end
end

def print_task(task)
    task_hash = task.to_h
    # we do +1 to account for the :
    widest_key = task_hash.keys.map(&.size).max + 1
    task_hash.each do |k, v|
        key = (k + ":").ljust(widest_key)
        key = key.colorize.bold if STDOUT.tty?
        puts "#{key} #{v.to_s}"
    end
end
