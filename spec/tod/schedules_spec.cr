require "time"

require "../spec_helper"

require "../../src/db"
require "../../src/status"
require "../../src/task"
require "../../src/schedules"

describe Scheduling do
    it "update_schedules works correctly" do
        two_thousand = Time.new 2000, 1, 1
        DATABASE.exec "
            insert into tasks (id, created_at, modified_at, name, schedule, status)
            values (1, ?, ?, 'thing to do', '0 0 * * 1', #{Status::Scheduling.to_i})
        ", two_thousand, two_thousand
        DATABASE.exec "
            insert into tasks (id, created_at, modified_at, name, status)
            values (2, ?, ?, 'thing to do', #{Status::Completed.to_i})
        ", two_thousand, two_thousand
        DATABASE.exec "insert into scheduled_tasks values (1, 2)"

        Scheduling.update_schedules two_thousand + 14.days

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

    it "get_last_scheduled_at works correctly" do
        two_thousand = Time.new 2000, 1, 1
        DATABASE.exec("
            insert into tasks (id, created_at, modified_at)
            values
                (1, ?, ?),
                (2, ?, ?),
                (3, ?, ?)
        ",
            two_thousand, two_thousand,
            two_thousand + 1.day, two_thousand + 1.day,
            two_thousand + 2.day, two_thousand + 2.day,
        )
        DATABASE.exec "
            insert into scheduled_tasks (parent_id, child_id)
            values (1, 1), (1, 2), (1, 3)
        "

        Scheduling.get_last_scheduled_at(1).should eq two_thousand + 2.day
    end
end
