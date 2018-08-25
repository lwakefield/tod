require "env"
require "file"
require "sqlite3"

DATABASE_FILE = ENV.fetch "TOD_DB", "sqlite3://#{File.expand_path "~/.tod.db"}"
DATABASE = DB.open DATABASE_FILE

def migrate_db
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
end

class SQLite3::ResultSet
    def to_array
        rows = [] of Hash(String, String)

        each do
            row = {} of String => String
            column_names.each { |v| row[v] = read.to_s }
            rows << row
        end

        return rows
    end
end
