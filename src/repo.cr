require "json"

require "time"

require "./db"
require "./status"

EPOCH = Time.epoch 0

# TODO use this instead of hashes
struct Task
    property id :          Int64?
    property name :        String
    property urgency :     Int32
    property importance :  Int32
    property tags :        Array(String)
    property status :      Status?
    property created_at :  Time?
    property modified_at : Time?
    property delay_until : Time?

    def initialize(
        @id          = nil,
        @name        = "",
        @urgency     = 0,
        @importance  = 0,
        @tags        = [] of String,
        @status      = nil,
        @created_at  = nil,
        @modified_at = nil,
        @delay_until = nil,
    ) end

    def priority
        @urgency + @importance
    end
end

class Repo
    def self.update_or_create_task (task : Task)
        #now = Time.utc_now

        ## TODO update_or_create_task should call update, or create, not vice-cersa

        ## we should update
        #unless task.id.nil?
        #    # Update the history
        #    DATABASE.exec "insert into tasks_history select
        #        id,
        #        created_at,
        #        modified_at,
        #        ? as deprecated_at,
        #        name,
        #        urgency,
        #        importance,
        #        status,
        #        tags,
        #        delay_until
        #    from tasks where id=?;
        #    ", now, task.id

        #    # Update the task
        #    updates = { "modified_at" => now }
        #    updates["name"]       = task.name unless task.name.nil?
        #    updates["urgency"]    = task.urgency unless task.urgency.nil?
        #    updates["importance"] = task.importance unless task.importance.nil?
        #    updates["importance"] = task.importance unless task.importance.nil?
        #    updates["status"]     = task.status.to_s unless task.status.nil?
        #    updates["tags"]       = task.tags.to_json unless (task.tags).nil?

        #    q = <<-QUERY
        #        update tasks set
        #            #{ updates.keys.map { |v| "#{v} = ?" }.join ", "}
        #        where id = ?
        #    QUERY

        #    DATABASE.exec q, updates.values + [ id ]
        #    return
        #end

        ## Create the task for the first time
        #if task.id.nil?
        #    q = <<-QUERY
        #        insert into tasks
        #        (created_at, modified_at, name, urgency, importance, status, tags)
        #        values(?, ?, ?, ?, ?, ?, ?)
        #    QUERY

        #    DATABASE.exec(q, [
        #        now,
        #        now,
        #        task.name,
        #        task.urgency,
        #        task.importance,
        #        task.status,
        #        task.tags.to_json
        #    ])
        #    return
        #end
    end

    def self.update_or_create_task (task)
        id          = task.fetch("id", nil)
        name        = task.fetch("name", nil)
        urgency     = task.fetch("urgency", nil)
        importance  = task.fetch("importance", nil)
        tags        = task.fetch("tags", nil).as(Array(String)?)
        status      = task.fetch("status", nil).as(Int32?)
        delay_until = task.fetch("delay_until", nil).as(Time?)
        now = Time.utc_now

        # Update the history
        unless id.nil?
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
            ", now, id
        end

        # Create the task for the first time
        if id.nil?
            q = <<-QUERY
                insert into tasks
                (created_at, modified_at, name, urgency, importance, status, tags)
                values(?, ?, ?, ?, ?, ?, ?)
            QUERY

            DATABASE.exec(q, [now, now, name, urgency, importance, status, tags.to_json])
            return
        end

        # Update the task
        updates = { "modified_at" => now.to_s }
        updates["name"]       = name.as(String) unless name.nil?
        updates["urgency"]    = urgency.as(String) unless urgency.nil?
        updates["importance"] = importance.as(String) unless importance.nil?
        updates["importance"] = importance.as(String) unless importance.nil?
        updates["status"]     = status.to_s unless status.nil?
        updates["tags"]       = tags.to_json unless tags.nil?

        q = <<-QUERY
            update tasks set
                #{ updates.keys.map { |v| "#{v} = ?" }.join ", "}
            where id = ?
        QUERY

        DATABASE.exec q, updates.values + [ id ]
    end

    def self.create_task (task)
        raise "Cannot create task with id" if task.has_key?("id")

        update_or_create_task(task)
    end

    def self.update_task (task)
        raise "Cannot update task without id" unless task.has_key?("id")

        update_or_create_task(task)
    end

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

        task.modified_at = now

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
        row = DATABASE.query_one(
            "select * from tasks where id=?",
            [task_id],
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
        return Task.new(
            id:          row[:id],
            name:        row[:name],
            created_at:  row[:created_at],
            modified_at: row[:modified_at],
            urgency:     row[:urgency],
            importance:  row[:importance],
            status:      Status.from_value(row[:status]),
            tags:        Array(String).from_json(row[:tags]),
            delay_until: row[:delay_until],
        )
    end
end
