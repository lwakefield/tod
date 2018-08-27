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
end
