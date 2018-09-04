require "time"

require "../spec_helper"

require "../../src/cron"

alias Schedule = Cron::Schedule

ALL_MINUTES_OF_HOUR = (0..59).to_a
ALL_HOURS_OF_DAY = (0..23).to_a
ALL_DAYS_OF_MONTH = (1..31).to_a
ALL_MONTHS_OF_YEAR = (1..12).to_a
ALL_DAYS_OF_WEEK = (0..6).to_a

describe "Cron::Schedule#parse" do
    expectations = {
        "5 4 * * *" => {
            [5],
            [4],
            ALL_DAYS_OF_MONTH,
            ALL_MONTHS_OF_YEAR,
            ALL_DAYS_OF_WEEK
        },
        "1-5 * * * *" => {
            [1,2,3,4,5],
            ALL_HOURS_OF_DAY,
            ALL_DAYS_OF_MONTH,
            ALL_MONTHS_OF_YEAR,
            ALL_DAYS_OF_WEEK
        },
        "*/5 * * * *" => {
            (0..59).step(5).to_a,
            ALL_HOURS_OF_DAY,
            ALL_DAYS_OF_MONTH,
            ALL_MONTHS_OF_YEAR,
            ALL_DAYS_OF_WEEK
        },
        "0-30/5 * * * *" => {
            (0..30).step(5).to_a,
            ALL_HOURS_OF_DAY,
            ALL_DAYS_OF_MONTH,
            ALL_MONTHS_OF_YEAR,
            ALL_DAYS_OF_WEEK
        },
        "1,2,3,4,4,4-10 * * * *" => {
            (1..10).to_a,
            ALL_HOURS_OF_DAY,
            ALL_DAYS_OF_MONTH,
            ALL_MONTHS_OF_YEAR,
            ALL_DAYS_OF_WEEK
        },
        "@hourly" => {
            [0],
            ALL_HOURS_OF_DAY,
            ALL_DAYS_OF_MONTH,
            ALL_MONTHS_OF_YEAR,
            ALL_DAYS_OF_WEEK
        },
    }
    expectations.each do |input, expectation|
        it "parses #{input}" {
            Schedule.parse(input).should eq Schedule.new *expectation
        }
    end
end

describe "Cron::Schedule.parse" do
    # this is a Saturday
    from_time = Time.new(2000, 1, 1)
    expectations = {
        "@hourly"     => from_time + 1.hour,
        "* * * * *"   => from_time + 1.minute,
        "*/5 * * * *" => from_time + 5.minute,
        "@weekly"     => from_time + 1.day,
        "@monthly"    => from_time + 1.month,
        "@yearly"     => from_time + 1.year,
    }
    expectations.each do |input, expectation|
        it "gets next #{input}" {
            Schedule.parse(input).next(from_time).should eq expectation
        }
    end
end
