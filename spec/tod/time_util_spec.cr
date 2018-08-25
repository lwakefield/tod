require "time"

require "../spec_helper"
require "../../src/time_util"

alias DayOfWeek = Time::DayOfWeek

ONE_MINUTE = Time::Span.new(0, 1, 0)
ONE_HOUR = ONE_MINUTE * 60
ONE_DAY = ONE_HOUR * 24

describe "Time::Span" do
    describe "parse" do
        tests = {
            "1mo" => 1.month,
            "1 mo" => 1.month,
            "1 month" => 1.month,
            "1 months" => 1.month,
            "12 months" => 12.month,

            "1d" => 1.days,
            "1 d" => 1.days,
            "1 day" => 1.days,
            "1 days" => 1.days,
            "12 days" => 12.days,

            "1h" => 1.hours,
            "1 h" => 1.hours,
            "1 hour" => 1.hours,
            "1 hours" => 1.hours,
            "12 hours" => 12.hours,

            "1m" => 1.minutes,
            "1 m" => 1.minutes,
            "1 min" => 1.minutes,
            "1 minute" => 1.minutes,
            "1 minutes" => 1.minutes,
            "12 minutes" => 12.minutes,
        }
        tests.each do |input, output|
            it "Time::Span.parse #{input}" { Time::Span.parse(input).should eq output }
        end
    end
end

WEDNESDAY = Time.new 2018, 8, 22
SUNDAY = Time.new 2018, 8, 26

describe Time do
    describe "#this" do
        tests = {
            DayOfWeek::Thursday => WEDNESDAY + 1.days,
            DayOfWeek::Friday => WEDNESDAY + 2.days,
            DayOfWeek::Saturday => WEDNESDAY + 3.days,
            DayOfWeek::Monday => WEDNESDAY + 5.days,
            DayOfWeek::Wednesday => WEDNESDAY + 7.days,
        }

        tests.each do |input, output|
            it "evaluates wednesday -> this #{input}" { WEDNESDAY.this(input).should eq output }
        end
    end

    describe "#next" do
        tests = {
            DayOfWeek::Thursday => WEDNESDAY + 8.days,
            DayOfWeek::Friday => WEDNESDAY + 9.days,
            DayOfWeek::Saturday => WEDNESDAY + 10.days,
            DayOfWeek::Sunday => WEDNESDAY + 4.days, # Sunday is the beginning of the week!

            DayOfWeek::Monday => WEDNESDAY + 5.days,
            DayOfWeek::Tuesday => WEDNESDAY + 6.days,
            DayOfWeek::Tuesday => WEDNESDAY + 6.days,
        }

        tests.each do |input, output|
            it "evaluates wednesday -> next #{input}" { WEDNESDAY.next(input).should eq output }
        end

        it "evaluates Sunday -> next Sunday" { SUNDAY.next(DayOfWeek::Sunday).should eq SUNDAY + 7.days }
        it "evaluates Sunday -> next Saturday" { SUNDAY.next(DayOfWeek::Saturday).should eq SUNDAY + 13.days }
    end

    describe ">>" do
        tests = {
            "this-thursday" => WEDNESDAY + 1.days,
            "this-sunday" => WEDNESDAY + 4.days,

            "next-thursday" => WEDNESDAY + 8.days,
            "next-sunday" => WEDNESDAY + 4.days,

            "1mo" => WEDNESDAY + 1.month,
            "1d" => WEDNESDAY + 1.day,
            "1h" => WEDNESDAY + 1.hour,
        }

        tests.each do |input, output|
            it "evaluates wednesday >> #{input}" { (WEDNESDAY >> input).should eq output }
        end
    end
end
