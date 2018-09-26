require "spec"
require "env"
require "file"

TEST_DATABASE_FILE = "#{__DIR__}/test.db"
ENV["TOD_DB"] = "sqlite3://#{TEST_DATABASE_FILE}"

require "../src/db"

Spec.before_each do
    DATABASE.exec "drop table if exists tasks"
    DATABASE.exec "drop table if exists tasks_history"
    DATABASE.exec "drop table if exists scheduled_tasks"
    migrate_db
end
