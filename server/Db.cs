using Microsoft.Data.Sqlite;

namespace PamBackend;

public static class Db
{
    private static string _connectionString = "";

    public static void Init(string path)
    {
        _connectionString = $"Data Source={path}";

        using var conn = Open();
        using var cmd = conn.CreateCommand();

        cmd.CommandText = """
            CREATE TABLE IF NOT EXISTS users (
              id            INTEGER PRIMARY KEY AUTOINCREMENT,
              email         TEXT    NOT NULL UNIQUE,
              password_hash TEXT    NOT NULL,
              name          TEXT    NOT NULL,
              specialty     TEXT    NOT NULL DEFAULT 'Информационные технологии',
              study_year    INTEGER NOT NULL DEFAULT 3,
              created_at    TEXT    NOT NULL
            );

            CREATE TABLE IF NOT EXISTS notes (
              id         INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id    INTEGER NOT NULL REFERENCES users (id),
              title      TEXT    NOT NULL,
              content    TEXT    NOT NULL DEFAULT '',
              created_at TEXT    NOT NULL
            );

            CREATE TABLE IF NOT EXISTS tasks (
              id         INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id    INTEGER NOT NULL REFERENCES users (id),
              title      TEXT    NOT NULL,
              course     TEXT    NOT NULL,
              deadline   TEXT    NOT NULL,
              status     TEXT    NOT NULL,
              priority   TEXT    NOT NULL,
              created_at TEXT    NOT NULL
            );

            CREATE TABLE IF NOT EXISTS files (
                id         INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id    INTEGER NOT NULL REFERENCES users (id),
                name       TEXT    NOT NULL,
                mime_type  TEXT    NOT NULL,
                size       INTEGER NOT NULL,
                path       TEXT    NOT NULL,
                created_at TEXT    NOT NULL
            );

            CREATE TABLE IF NOT EXISTS task_files (
                task_id    INTEGER NOT NULL REFERENCES tasks (id) ON DELETE CASCADE,
                file_id    INTEGER NOT NULL REFERENCES files (id) ON DELETE CASCADE,
                created_at TEXT    NOT NULL,
                PRIMARY KEY (task_id, file_id)
            );

            CREATE TABLE IF NOT EXISTS courses (
              id         INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id    INTEGER NOT NULL REFERENCES users (id),
              name       TEXT    NOT NULL,
              teacher    TEXT    NOT NULL,
              day        TEXT    NOT NULL,
              time       TEXT    NOT NULL,
              room       TEXT    NOT NULL,
              created_at TEXT    NOT NULL
            );

            CREATE TABLE IF NOT EXISTS course_sessions (
              id         INTEGER PRIMARY KEY AUTOINCREMENT,
              course_id  INTEGER NOT NULL REFERENCES courses (id) ON DELETE CASCADE,
              day        TEXT    NOT NULL,
              time       TEXT    NOT NULL,
              room       TEXT    NOT NULL,
              format     TEXT    NOT NULL DEFAULT 'Очное'
            );
            """;

        cmd.ExecuteNonQuery();

        // Миграции для существующих баз данных.
        EnsureColumn(
            conn,
            "users",
            "specialty",
            "TEXT NOT NULL DEFAULT 'Информационные технологии'"
        );

        EnsureColumn(
            conn,
            "users",
            "study_year",
            "INTEGER NOT NULL DEFAULT 3"
        );

        EnsureColumn(
            conn,
            "course_sessions",
            "format",
            "TEXT NOT NULL DEFAULT 'Очное'"
        );

        EnsureColumn(
            conn,
            "tasks",
            "course_id",
            "INTEGER REFERENCES courses(id) ON DELETE CASCADE"
        );

        // Переносим старое расписание каждого курса
        // в отдельную таблицу занятий.
        MigrateCourseSessions(conn);
        MigrateTaskCourses(conn);
    }

    private static void MigrateCourseSessions(SqliteConnection conn)
    {
        using var cmd = conn.CreateCommand();

        cmd.CommandText = """
            INSERT INTO course_sessions (course_id, day, time, room)
            SELECT c.id, c.day, c.time, c.room
            FROM courses c
            WHERE NOT EXISTS (
                SELECT 1
                FROM course_sessions s
                WHERE s.course_id = c.id
            );
            """;

        cmd.ExecuteNonQuery();
    }

    private static void MigrateTaskCourses(SqliteConnection conn)
    {
        using var cmd = conn.CreateCommand();

        cmd.CommandText = """
            UPDATE tasks
            SET course_id = (
                SELECT courses.id
                FROM courses
                WHERE courses.user_id = tasks.user_id
                AND courses.name = tasks.course
                ORDER BY courses.id
                LIMIT 1
            )
            WHERE course_id IS NULL;

            CREATE INDEX IF NOT EXISTS idx_tasks_course_id
            ON tasks(course_id);
            """;

        cmd.ExecuteNonQuery();
    }
    
    private static void EnsureColumn(
        SqliteConnection conn,
        string tableName,
        string columnName,
        string columnDefinition)
    {
        using var cmd = conn.CreateCommand();

        cmd.CommandText = $"PRAGMA table_info({tableName});";

        using var reader = cmd.ExecuteReader();

        var columnExists = false;

        while (reader.Read())
        {
            if (reader["name"].ToString() == columnName)
            {
                columnExists = true;
                break;
            }
        }

        reader.Close();

        if (!columnExists)
        {
            using var alterCmd = conn.CreateCommand();

            alterCmd.CommandText =
                $"ALTER TABLE {tableName} ADD COLUMN {columnName} {columnDefinition};";

            alterCmd.ExecuteNonQuery();
        }
    }

    public static SqliteConnection Open()
    {
        var conn = new SqliteConnection(_connectionString);
        conn.Open();

        using var cmd = conn.CreateCommand();
        cmd.CommandText = "PRAGMA foreign_keys = ON;";
        cmd.ExecuteNonQuery();

        return conn;
    }

    public static string NowIso() =>
        DateTime.UtcNow.ToString("o");
}

public static class SqliteExtensions
{
    public static SqliteCommand Cmd(
        this SqliteConnection conn,
        string sql,
        params (string Name, object? Value)[] args)
    {
        var cmd = conn.CreateCommand();
        cmd.CommandText = sql;

        foreach (var (name, value) in args)
        {
            cmd.Parameters.AddWithValue(
                name,
                value ?? DBNull.Value);
        }

        return cmd;
    }

    public static long LastInsertRowId(this SqliteConnection conn)
    {
        using var cmd = conn.Cmd("SELECT last_insert_rowid()");
        return (long)cmd.ExecuteScalar()!;
    }
}
