require "time"

RGX_ALL = /^\*$/
RGX_SINGLE_VAL = /^\d+$/
RGX_RANGE = /^(?<start>\d+)\-(?<end>\d+)$/
RGX_ALL_STEP = /^\*\/(?<step>\d+)$/
RGX_RANGE_STEP = /^(?<start>\d+)\-(?<end>\d+)\/(?<step>\d+)$/

module Cron
    record(
        Schedule,
        minute :       Array(Int32),
        hour :         Array(Int32),
        day_of_month : Array(Int32),
        month :        Array(Int32),
        day_of_week :  Array(Int32),
    )
    SCHEDULE_ALIASES = {
        "@yearly":  "0 0 1 1 *",
        "@annualy": "0 0 1 1 *",
        "@monthly": "0 0 1 * *",
        "@weekly":  "0 0 * * 0",
        "@daily":   "0 0 * * *",
        "@hourly":  "0 * * * *",
    }
end

struct Cron::Schedule
    def next(from_time : Time)
        hours_in_day = 24
        minutes_in_day = hours_in_day * 60
        minutes_in_year = minutes_in_day * 366

        # TODO: this is not very efficient...
        minutes_to_add = (1..minutes_in_year).find do |minutes_to_add|
            test_time = from_time + minutes_to_add.minutes
            [
                minute.includes?(test_time.minute),
                hour.includes?(test_time.hour),
                day_of_month.includes?(test_time.day),
                month.includes?(test_time.month),
                day_of_week.includes?(test_time.day_of_week.value),
            ].all?
        end

        raise "Could not find next scheduled time" if minutes_to_add.nil?
        (from_time + minutes_to_add.minutes).at_beginning_of_minute
    end

    def self.parse (cron_schedule_str)
        unless (aliased = SCHEDULE_ALIASES[cron_schedule_str]?).nil?
            return self.parse(aliased)
        end

        parts = cron_schedule_str.split(" ")

        raise "Malformed crontab: #{cron_schedule_str}" if parts.size != 5

        minute       = parse_minute parts[0]
        hour         = parse_hour parts[1]
        day_of_month = parse_day_of_month parts[2]
        month        = parse_month parts[3]
        day_of_week  = parse_day_of_week parts[4]

        self.new(
            minute,
            hour,
            day_of_month,
            month,
            day_of_week
        )
    end

    private def self.parse_minute (field)
        parse_field field, (0..59)
    end

    private def self.parse_hour (field)
        parse_field field, (0..23)
    end

    private def self.parse_day_of_month (field)
        # TODO validate for the given month
        parse_field field, (1..31)
    end

    private def self.parse_month (field)
        parse_field field, (1..12)
    end

    private def self.parse_day_of_week (field)
        parse_field field, (0..6)
    end

    private def self.parse_field(field, available_range)
        field.split(",").reduce([] of Int32) do |acc, v|
            if v.match RGX_ALL
                acc + available_range.to_a
            elsif v.match RGX_SINGLE_VAL
                acc + [v.to_i]
            elsif (match = v.match RGX_RANGE)
                start, endd = match["start"].to_i, match["end"].to_i
                acc + (start .. endd).to_a
            elsif (match = v.match RGX_ALL_STEP )
                step = match["step"].to_i
                acc + available_range.step(step).to_a
            elsif (match = v.match RGX_RANGE_STEP)
                start, endd, step = match["start"].to_i, match["end"].to_i, match["step"].to_i
                acc + (start .. endd).step(step).to_a
            else
                [] of Int32
            end.uniq
        end
    end
end
