require "time"

require "../spec_helper"

require "../../src/db"
require "../../src/status"
require "../../src/task"
require "../../src/scheduling"

TWO_THOUSAND = Time.new 2000, 1, 1

describe Scheduling do
    it "update_schedules works correctly" do
        DATABASE.exec "
            insert into tasks (id, created_at, modified_at, name, schedule, status)
            values
                (1, ?, ?, 'thing to do', '0 0 * * 1', #{Status::Scheduling.to_i}),
                (2, ?, ?, 'thing to do', null,        #{Status::Completed.to_i})
        ", TWO_THOUSAND, TWO_THOUSAND, TWO_THOUSAND, TWO_THOUSAND
        DATABASE.exec "insert into scheduled_tasks values (1, 2)"

        Scheduling.update_schedules TWO_THOUSAND + 14.days

        DATABASE.query_all "select * from tasks where schedule is null" do |row|
            row.column_names.map { row.read }.join ", "
        end.join("\n").should eq "\
            2, 2000-01-01 05:00:00.000, 2000-01-01 05:00:00.000, thing to do, 0, 0, 3, [], , \n\
            3, 2000-01-03 00:00:00.000, 2000-01-03 00:00:00.000, thing to do, 0, 0, 1, [], , \n\
            4, 2000-01-10 00:00:00.000, 2000-01-10 00:00:00.000, thing to do, 0, 0, 1, [], , \
        "

        DATABASE.query_all "select * from scheduled_tasks" do |row|
            row.column_names.map { row.read }.join ", "
        end.join("\n").should eq "\
            1, 2\n\
            1, 3\n\
            1, 4\
        "
    end

    it "update_schedules for the first time" do
        DATABASE.exec "
            insert into tasks (id, created_at, modified_at, name, schedule, status)
            values
                (1, ?, ?, 'thing to do', '0 0 * * 1', #{Status::Scheduling.to_i})
        ", TWO_THOUSAND, TWO_THOUSAND

        Scheduling.update_schedules TWO_THOUSAND + 14.days

        DATABASE.query_all "select * from tasks where schedule is null" do |row|
            row.column_names.map { row.read }.join ", "
        end.join("\n").should eq "\
            2, 2000-01-03 00:00:00.000, 2000-01-03 00:00:00.000, thing to do, 0, 0, 1, [], , \n\
            3, 2000-01-10 00:00:00.000, 2000-01-10 00:00:00.000, thing to do, 0, 0, 1, [], , \
        "

        DATABASE.query_all "select * from scheduled_tasks" do |row|
            row.column_names.map { row.read }.join ", "
        end.join("\n").should eq "\
            1, 2\n\
            1, 3\
        "
    end

    it "get_last_scheduled_at works correctly" do
        DATABASE.exec("
            insert into tasks (id, created_at, modified_at)
            values
                (1, ?, ?),
                (2, ?, ?),
                (3, ?, ?)
        ",
            TWO_THOUSAND, TWO_THOUSAND,
            TWO_THOUSAND + 1.day, TWO_THOUSAND + 1.day,
            TWO_THOUSAND + 2.day, TWO_THOUSAND + 2.day,
        )
        DATABASE.exec "
            insert into scheduled_tasks (parent_id, child_id)
            values (1, 1), (1, 2), (1, 3)
        "

        Scheduling.get_last_scheduled_at(1).should eq TWO_THOUSAND + 2.day
    end
end
