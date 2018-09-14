require "json"

require "time"

require "./db"
require "./status"
require "./task"

class Repo
    def self.create_task (task : Task)
        raise "Cannot create task with id" unless task.id.nil?
        now = Time.utc_now
        task.created_at = now
        task.modified_at = now

        q = <<-QUERY
            insert into tasks
            (created_at, modified_at, name, urgency, importance, status, tags, delay_until)
            values(?, ?, ?, ?, ?, ?, ?, ?)
        QUERY

        result = DATABASE.exec(q, [
            now,
            now,
            task.name,
            task.urgency,
            task.importance,
            task.status.as(Status).value,
            task.tags.to_json,
            task.delay_until
        ])

        raise "Error creating task: #{task}" if result.rows_affected != 1
        task.id = result.last_insert_id
        return task
    end

    def self.update_task (task : Task)
        raise "Cannot update task without id" if task.id.nil?

        now = Time.utc_now

        # Update the history table first
        DATABASE.exec "insert into tasks_history select
            id,
            created_at,
            modified_at,
            ? as deprecated_at,
            name,
            urgency,
            importance,
            status,
            tags,
            delay_until
        from tasks where id=?;
        ", now, task.id

        q = <<-QUERY
            update tasks set
                created_at=?,
                modified_at=?,
                name=?,
                urgency=?,
                importance=?,
                status=?,
                tags=?,
                delay_until=?
            where id = ?
        QUERY

        task.modified_at = now

        result = DATABASE.exec(q, [
            now,
            now,
            task.name,
            task.urgency,
            task.importance,
            task.status.as(Status).value,
            task.tags.to_json,
            task.delay_until,
            task.id
        ])

        return task
    end

    def self.get_task (task_id)
        rows = DATABASE.query "select * from tasks where id=?", task_id
        tasks = Task.from_rs rows
        raise "no tasks found" if tasks.size == 0
        return tasks.first
    end

    def self.get_tasks (task_ids)
        id_conditions = ["id=?"] * task_ids.size

        rows = DATABASE.query "select * from tasks where #{id_conditions.join " or "}", task_ids
        tasks = Task.from_rs rows
        raise "no tasks found" if tasks.size == 0
        return tasks
    end

    def self.schedule_task (task_id, schedule)
        q = <<-QUERY
            insert into schedules
            (task_id, schedule)
            values(?, ?)
        QUERY

        DATABASE.exec q, task_id, schedule
    end

    def self.update_schedules
        q = <<-QUERY
            select id, schedule
            from tasks
            where schedule is not null
        QUERY
        schedules = DATABASE.query q, as: { Int32, String }

        DATABASE.query "select * from tasks where id in (select * from scheduled)"

        # we want to update the current existing schedules.
        # we call the scheduling task the parent, and the scheduled task the child
        # from the parent, we want to find the newest child
        # from the newest child, we want to fill any gaps from then, and now.

        # when creating a child task, we set the created_at based off the
        # schedule, ie. not Time.now

        schedules.each do |parent_id, schedule|
            q = <<-QUERY
                select * from tasks
                where id in (
                    select child_id from scheduled
                    where parent_id = ?
                )
                order by id desc
                limit 1
            QUERY
            last_scheduled = DATABASE.query_one q, parent_id, as: Task

            cron_schedule = Cron::Schedule.parse(last_scheduled.schedule)
            next_scheduled = last_scheduled
            now = Time.now
            while next_scheduled < now
            end
        end

    end
end
