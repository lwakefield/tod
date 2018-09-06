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
    # pre-formatting
    to_format = tasks.map do |task|
        { task, task.to_h }
    end

    to_format.each do |task, formatted|
        formatted["tags"] = task.tags.join ","
    end

    # Work out the size for each column
    longest_strings = { } of String => Int32
    COLUMNS.each { |v| longest_strings[v] = v.size }
    to_format.each do |task, formatted|
        formatted.each do |k, v|
            next unless COLUMNS.includes? k

            if v.to_s.size > longest_strings[k]
                longest_strings[k] = v.to_s.size
            end
        end
    end

    # trim the name if it is too long to fit on the screen
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

        to_format.each do |task, formatted|
            next if task.name.size <= name_max_space

            ellipsis = "..."
            len = name_max_space - ellipsis.size
            formatted["name"] = task.name[0...len] + ellipsis
        end
    end

    # Print the headers
    headers = COLUMNS.map { |v| v.ljust(longest_strings[v])[0...longest_strings[v]] }.join " "
    headers = headers.colorize.bold if STDOUT.tty?
    puts headers

    # Print the rows
    to_format.map do |task, formatted|
        row = COLUMNS.map { |v| formatted[v].to_s.ljust(longest_strings[v]) }.join " "

        if task.status == Status::Started
            row = row.colorize.fore(:green)
        elsif task.priority >= 3
            row = row.colorize.fore(:red)
        elsif task.priority >= 1
            row = row.colorize.fore(:yellow)
        end

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
