require "time"
require "regex"

struct Time
    def this (day_of_week)
        curr_day = self + 1.0.days
        while curr_day.day_of_week != day_of_week
            curr_day = curr_day + 1.0.days
        end
        return curr_day
    end

    def next (day_of_week)
        curr_day = self.this(Time::DayOfWeek::Sunday)

        while curr_day.day_of_week != day_of_week
            curr_day = curr_day + 1.0.days
        end
        return curr_day
    end

    def >> (str)
        if str == "tomorrow"
            return (self + 1.day).at_beginning_of_day
        elsif str.match /next\W?week/
            return (self + 1.week).at_beginning_of_day
        elsif (match = str.match(/this\W?(\w+)/))
            return self.this Time::DayOfWeek.parse(match[1])
        elsif (match = str.match(/next\W?(\w+)/))
            return self.next Time::DayOfWeek.parse(match[1])
        else
            begin
                span = Time::Span.parse(str)
                shifted = self + span
                if span.is_a? Time::MonthSpan ||span.as(Time::Span).days >= 1
                    return shifted.at_beginning_of_day
                end
                return shifted
            rescue
                raise Exception.new "Could not shift #{self} by #{str}"
            end
        end
    end
end

enum Time::DayOfWeek
    def self.parse (str)
        case str.downcase
        when "m", "mon", "monday"
            return Time::DayOfWeek::Monday
        when "tu", "tue", "tuesday"
            return Time::DayOfWeek::Tuesday
        when "w", "wed", "wednesday"
            return Time::DayOfWeek::Wednesday
        when "th", "thu", "thur", "thurs", "thursday"
            return Time::DayOfWeek::Thursday
        when "f", "fri", "friday"
            return Time::DayOfWeek::Friday
        when "sa", "sat", "saturday"
            return Time::DayOfWeek::Saturday
        when "su", "sun", "sunday"
            return Time::DayOfWeek::Sunday
        end

        raise ArgumentError.new "Cannot parse day of week: #{str}"
    end
end

struct Time::Span
    def self.parse (str)
        month_match = str.match(/^(\d+)\s?mo(nths?)?$/)
        if month_match
            return month_match[1].to_i.months
        end

        day_match = str.match(/^(\d+)\s?d(ays?)?$/)
        if day_match
            return day_match[1].to_f.days
        end

        hour_match = str.match(/^(\d+)\s?h(ours?)?$/)
        if hour_match
            return hour_match[1].to_f.hours
        end

        minute_match = str.match(/^(\d+)\s?m(in((ute(s)?)?))?$/)
        if minute_match
            return minute_match[1].to_f.minutes
        end

        raise ArgumentError.new "Cannot parse Time::Span #{str}"
    end
end
