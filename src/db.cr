require "env"
require "file"
require "sqlite3"

DATABASE_FILE = ENV.fetch "TOD_DB", "sqlite3://#{File.expand_path "~/.tod.db"}"
DATABASE = DB.open DATABASE_FILE

def migrate_db
    # TODO either work out how to change the schema to support default
    # timestamp, or drop this approach
    DATABASE.exec "create table if not exists tasks (
        id integer primary key,
        created_at text,
        modified_at text,
        name text default '',
        urgency integer default 0,
        importance integer default 0,
        status integer default 0,
        tags json default '[]'
    )"
    DATABASE.exec "create table if not exists tasks_history (
        id integer,
        created_at text,
        modified_at text,
        deprecated_at text,
        name text default '',
        urgency integer default 0,
        importance integer default 0,
        status integer default 0,
        tags json default '[]'
    )"

    begin
        DATABASE.exec "alter table tasks add column delay_until text"
        DATABASE.exec "alter table tasks_history add column delay_until text"
    rescue ex : SQLite3::Exception
        raise ex unless ex.message == "duplicate column name: delay_until"
    end

    begin
        DATABASE.exec "alter table tasks add column schedule text"
        DATABASE.exec "alter table tasks_history add column schedule text"
    rescue ex : SQLite3::Exception
        raise ex unless ex.message == "duplicate column name: schedule"
    end

    DATABASE.exec "create table if not exists scheduled_tasks (
        parent_id integer,
        child_id integer
    )"
end
