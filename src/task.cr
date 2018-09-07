require "time"

module TagsConverter
    def self.from_rs (rs)
        return Array(String).from_json rs.read(String)
    end
end

module StatusConverter
    def self.from_rs(rs)
        Status.from_value rs.read(Int32)
    end
end

module BaseTask
    def priority
        @urgency + @importance
    end

    def age
        return "0m" if Time.nil?

        span = Time.utc_now - @created_at.as(Time)
        return "#{span.days}d" if span.days > 0
        return "#{span.hours}h" if span.hours > 0
        return "#{span.minutes}m"
    end

    def to_h
        {% begin %}
            {
                "priority" => priority,
                "age" => age,
                {% for var in @type.instance_vars %}
                    "{{var.name}}" => @{{var.name}},
                {% end %}
            }
        {% end %}
    end

end

struct Task
    include BaseTask

    DB.mapping({
        id:          Int64?,
        created_at:  Time?,
        modified_at: Time?,
        name:        String,
        urgency:     Int32,
        importance:  Int32,
        status:      { type: Status, converter: StatusConverter },
        tags:        { type: Array(String), converter: TagsConverter },
        delay_until: Time?
    })

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
end

struct DeprecatedTask
    include BaseTask

    DB.mapping({
        id:            Int64?,
        created_at:    Time?,
        modified_at:   Time?,
        name:          String,
        urgency:       Int32,
        importance:    Int32,
        status:        { type: Status, converter: StatusConverter },
        tags:          { type: Array(String), converter: TagsConverter },
        delay_until:   Time?,
        deprecated_at: Time?
    })

    def initialize(
        @id            = nil,
        @name          = "",
        @urgency       = 0,
        @importance    = 0,
        @tags          = [] of String,
        @status        = nil,
        @created_at    = nil,
        @modified_at   = nil,
        @delay_until   = nil,
        @deprecated_at = nil
    ) end
end
