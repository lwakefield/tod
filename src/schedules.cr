require "time"

require "./repo"
require "./db"
require "./status"
require "./task"
require "./cron"

# TODO: rename the file to scheduling.cr
module Scheduling
    def self.update_schedules (update_until = Time.now)
        schedules = DATABASE.query_all "
            select *
            from tasks
            where
                schedule is not null
                and status = #{Status::Scheduling.to_i}
        ", as: Task
        schedules.each do |parent|
            update_scheduling_task parent, update_until
        end
    end

    def self.update_scheduling_task (parent, update_until = Time.now)
        last_scheduled_at = (get_last_scheduled_at(parent.id) || parent.created_at).as Time
        schedule = Cron::Schedule.parse(parent.schedule.as(String))

        while (last_scheduled_at = schedule.next last_scheduled_at) < update_until
            child = parent.dup
            child.id = nil
            child.created_at = last_scheduled_at
            child.modified_at = last_scheduled_at
            child.status = Status::Upcoming
            child.schedule = nil

            child = Repo.create_task child

            DATABASE.exec "
                insert into scheduled_tasks (parent_id, child_id)
                values (?, ?)
            ", parent.id, child.id
        end
    end

    def self.get_last_scheduled_at (parent_id)
        # TODO if we update parent.schedule, then this may not be correct...
        q = <<-QUERY
            select tasks.created_at from tasks, scheduled_tasks
            where
                scheduled_tasks.parent_id = #{parent_id}
                and tasks.id = scheduled_tasks.child_id
            order by tasks.created_at desc
            limit 1
        QUERY
        DATABASE.query_one? q, as: Time
    end
end
