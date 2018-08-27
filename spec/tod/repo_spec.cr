require "time"

require "../spec_helper"

require "../../src/repo"
require "../../src/db"
require "../../src/status"
require "../../src/task"

describe "Repo.create_task" do
    it "creates a simple task" do
        task = Task.new(status: Status::Upcoming)
        created_task = Repo.create_task task

        row = DATABASE.query_one(
            "select * from tasks",
            as: {
                id:          Int64,
                created_at:  Time,
                modified_at: Time,
                name:        String,
                urgency:     Int32,
                importance:  Int32,
                status:      Int32,
                tags:        String,
                delay_until: Time?
        })
        row[:id].should eq 1
        row[:created_at].should be_truthy
        row[:modified_at].should be_truthy
        row[:name].should eq ""
        row[:urgency].should eq 0
        row[:importance].should eq 0
        row[:status].should eq Status::Upcoming.value
        row[:tags].should eq "[]"
        row[:delay_until].should eq nil

        created_task.id.should eq 1
        created_task.created_at.should be_truthy
        created_task.modified_at.should be_truthy
        created_task.name.should eq ""
        created_task.urgency.should eq 0
        created_task.importance.should eq 0
        created_task.status.should eq Status::Upcoming
        created_task.tags.should eq [] of String
        created_task.delay_until.should eq nil
    end
end

describe "Repo.get_task" do
    it "gets a single task" do
        q = <<-QUERY
            insert into tasks
            (created_at, modified_at, name, urgency, importance, status, tags, delay_until)
            values(?, ?, ?, ?, ?, ?, ?, ?)
        QUERY
        now = Time.utc 2018, 8, 25
        vals = [now, now, "foo", 0, 1, Status::Upcoming.value, "[]", nil]
        DATABASE.exec(q, vals)

        task = Repo.get_task 1
        task.should eq Task.new(
            id: 1i64,
            name: "foo",
            created_at: now,
            modified_at: now,
            urgency: 0,
            importance: 1,
            status: Status::Upcoming,
            tags: [] of String,
            delay_until: nil,
        )
    end
end

describe "Repo.update_task" do
    it "updates a task" do
        now = Time.utc_now
        task = Task.new(
            id: 1i64,
            name: "foo",
            created_at: now,
            modified_at: now,
            urgency: 0,
            importance: 1,
            status: Status::Upcoming,
            tags: [] of String,
            delay_until: nil,
        )

        q = <<-QUERY
            insert into tasks
            (id, created_at, modified_at, name, urgency, importance, status, tags, delay_until)
            values(?, ?, ?, ?, ?, ?, ?, ?, ?)
        QUERY
        DATABASE.exec(q,
            [
                task.id,
                now,
                now,
                task.name,
                task.urgency,
                task.importance,
                task.status.as(Status).value,
                task.tags.to_json,
                task.delay_until
            ]
        )

        task.status = Status::Completed
        updated_task = Repo.update_task(task)
        updated_task.modified_at.should_not eq now
        updated_task.status.should eq Status::Completed

        status = DATABASE.query_one "select status from tasks where id=1", as: Int32
        status.should eq Status::Completed.value

        count = DATABASE.query_one "select count(*) from tasks_history where id=1", as: Int32
        count.should eq 1
    end
end
