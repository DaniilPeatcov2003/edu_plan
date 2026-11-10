using Microsoft.Data.Sqlite;

namespace PamBackend;

public record CourseSessionItem(
    long Id,
    string Day,
    string Time,
    string Room,
    string Format
);

public record CourseSessionInput(
    string? Day,
    string? Time,
    string? Room,
    string? Format = "Очное"
);

public record CourseItem(
    long Id,
    string Name,
    string Teacher,
    string Day,
    string Time,
    string Room,
    string CreatedAt,
    List<CourseSessionItem> Sessions
);

public record CourseInput(
    string? Name,
    string? Teacher,
    string? Day,
    string? Time,
    string? Room,
    List<CourseSessionInput>? Sessions = null
);

public static class Courses
{
    private static CourseItem ReadCourse(SqliteDataReader reader) => new(
        reader.GetInt64(0),
        reader.GetString(1),
        reader.GetString(2),
        reader.GetString(3),
        reader.GetString(4),
        reader.GetString(5),
        reader.GetString(6),
        new List<CourseSessionItem>()
    );

    private static List<CourseSessionItem> FindSessions(
        SqliteConnection conn,
        long courseId)
    {
        var sessions = new List<CourseSessionItem>();

        using var cmd = conn.Cmd(
            """
            SELECT id, day, time, room, format
            FROM course_sessions
            WHERE course_id = $courseId
            ORDER BY
                CASE day
                    WHEN 'Понедельник' THEN 1
                    WHEN 'Вторник' THEN 2
                    WHEN 'Среда' THEN 3
                    WHEN 'Четверг' THEN 4
                    WHEN 'Пятница' THEN 5
                    WHEN 'Суббота' THEN 6
                    WHEN 'Воскресенье' THEN 7
                    ELSE 8
                END,
                time
            """,
            ("$courseId", courseId)
        );

        using var reader = cmd.ExecuteReader();

        while (reader.Read())
        {
            sessions.Add(new CourseSessionItem(
                reader.GetInt64(0),
                reader.GetString(1),
                reader.GetString(2),
                reader.GetString(3),
                reader.GetString(4)
            ));
        }

        return sessions;
    }

    private static CourseItem WithSessions(
        SqliteConnection conn,
        CourseItem course)
    {
        return course with
        {
            Sessions = FindSessions(conn, course.Id)
        };
    }

    private static CourseItem? Find(
        SqliteConnection conn,
        long userId,
        long id)
    {
        CourseItem? course;

        using (var cmd = conn.Cmd(
            """
            SELECT id, name, teacher, day, time, room, created_at
            FROM courses
            WHERE id = $id AND user_id = $userId
            """,
            ("$id", id),
            ("$userId", userId)
        ))
        {
            using var reader = cmd.ExecuteReader();
            course = reader.Read() ? ReadCourse(reader) : null;
        }

        return course is null ? null : WithSessions(conn, course);
    }

    private static List<CourseSessionInput>? NormalizeSessions(
        CourseInput input)
    {
        var sessions = input.Sessions;

        // Поддержка старого Flutter API:
        // day, time и room вместо массива sessions.
        if (sessions is null || sessions.Count == 0)
        {
            var day = Errors.Trimmed(input.Day);
            var time = Errors.Trimmed(input.Time);
            var room = Errors.Trimmed(input.Room);

            if (day is null || time is null || room is null)
                return null;

            return new List<CourseSessionInput>
            {
                new(day, time, room, "Очное")
            };
        }

        var result = new List<CourseSessionInput>();

        foreach (var session in sessions)
        {
            var day = Errors.Trimmed(session.Day);
            var time = Errors.Trimmed(session.Time);
            var room = Errors.Trimmed(session.Room);
            var format = Errors.Trimmed(session.Format) ?? "Очное";

            if (day is null || time is null || room is null)
                return null;

            result.Add(new CourseSessionInput(day, time, room, format));
        }

        return result;
    }

    private static void InsertSessions(
        SqliteConnection conn,
        long courseId,
        List<CourseSessionInput> sessions)
    {
        foreach (var session in sessions)
        {
            using var insert = conn.Cmd(
                """
                INSERT INTO course_sessions
                (course_id, day, time, room, format)
                VALUES
                ($courseId, $day, $time, $room, $format)
                """,
                ("$courseId", courseId),
                ("$day", session.Day),
                ("$time", session.Time),
                ("$room", session.Room),
                ("$format", session.Format)
            );

            insert.ExecuteNonQuery();
        }
    }

    
    public static IResult List(HttpContext context, int page = 1, int limit = 20, string search = "")
    {
        page = Math.Max(page, 1);
        limit = Math.Clamp(limit, 1, 100);

        var userId = Auth.CurrentUserId(context);
        var pattern = $"%{search.Trim()}%";

        const string where = """
            user_id = $userId
            AND (name LIKE $pattern OR teacher LIKE $pattern)
            """;

        using var conn = Db.Open();

        long total;

        using (var count = conn.Cmd(
            $"""
            SELECT COUNT(*)
            FROM courses
            WHERE {where}
            """,
            ("$userId", userId),
            ("$pattern", pattern)))
        {
            total = (long)count.ExecuteScalar()!;
        }

        var items = new List<CourseItem>();

        using (var cmd = conn.Cmd(
            $"""
            SELECT id, name, teacher, day, time, room, created_at
            FROM courses
            WHERE {where}
            ORDER BY id
            LIMIT $limit OFFSET $offset
            """,
            ("$userId", userId),
            ("$pattern", pattern),
            ("$limit", limit),
            ("$offset", (page - 1) * limit)))
        {
            using var reader = cmd.ExecuteReader();

            while (reader.Read())
                items.Add(ReadCourse(reader));
        }

        var result = items
            .Select(course => WithSessions(conn, course))
            .ToList();

        return Results.Json(new
        {
            items = result,
            page,
            limit,
            total
        });
    }


    public static IResult Create(
        HttpContext context,
        CourseInput input)
    {
        var name = Errors.Trimmed(input.Name);
        var teacher = Errors.Trimmed(input.Teacher);
        var sessions = NormalizeSessions(input);

        if (name is null || teacher is null || sessions is null)
        {
            return Errors.Validation(
                "name, teacher and at least one valid session are required"
            );
        }

        var firstSession = sessions[0];
        var userId = Auth.CurrentUserId(context);

        using var conn = Db.Open();

        using (var insert = conn.Cmd(
            """
            INSERT INTO courses
            (user_id, name, teacher, day, time, room, created_at)
            VALUES
            ($userId, $name, $teacher, $day, $time, $room, $createdAt)
            """,
            ("$userId", userId),
            ("$name", name),
            ("$teacher", teacher),
            ("$day", firstSession.Day),
            ("$time", firstSession.Time),
            ("$room", firstSession.Room),
            ("$createdAt", Db.NowIso())))
        {
            insert.ExecuteNonQuery();
        }

        var id = conn.LastInsertRowId();

        InsertSessions(conn, id, sessions);

        var course = Find(conn, userId, id)!;

        return Results.Created($"/courses/{course.Id}", course);
    }

    public static IResult GetOne(HttpContext context, long id)
    {
        using var conn = Db.Open();

        var course = Find(
            conn,
            Auth.CurrentUserId(context),
            id
        );

        return course is null
            ? Errors.NotFound("Course not found")
            : Results.Json(course);
    }

    public static IResult Update(
        HttpContext context,
        long id,
        CourseInput input)
    {
        var userId = Auth.CurrentUserId(context);

        using var conn = Db.Open();

        if (Find(conn, userId, id) is null)
            return Errors.NotFound("Course not found");

        var name = Errors.Trimmed(input.Name);
        var teacher = Errors.Trimmed(input.Teacher);
        var sessions = NormalizeSessions(input);

        if (name is null || teacher is null || sessions is null)
        {
            return Errors.Validation(
                "name, teacher and at least one valid session are required"
            );
        }

        var firstSession = sessions[0];

        using (var update = conn.Cmd(
            """
            UPDATE courses
            SET name = $name,
                teacher = $teacher,
                day = $day,
                time = $time,
                room = $room
            WHERE id = $id AND user_id = $userId
            """,
            ("$name", name),
            ("$teacher", teacher),
            ("$day", firstSession.Day),
            ("$time", firstSession.Time),
            ("$room", firstSession.Room),
            ("$id", id),
            ("$userId", userId)))
        {
            update.ExecuteNonQuery();
        }

        using (var delete = conn.Cmd(
            "DELETE FROM course_sessions WHERE course_id = $id",
            ("$id", id)))
        {
            delete.ExecuteNonQuery();
        }

        InsertSessions(conn, id, sessions);

        return Results.Json(Find(conn, userId, id)!);
    }

    public static IResult Delete(HttpContext context, long id)
    {
        var userId = Auth.CurrentUserId(context);

        using var conn = Db.Open();

        if (Find(conn, userId, id) is null)
            return Errors.NotFound("Course not found");

        // Удаляем занятия явно, чтобы не зависеть
        // от настройки foreign_keys в SQLite.
        using (var deleteSessions = conn.Cmd(
            "DELETE FROM course_sessions WHERE course_id = $id",
            ("$id", id)))
        {
            deleteSessions.ExecuteNonQuery();
        }

        using var delete = conn.Cmd(
            "DELETE FROM courses WHERE id = $id AND user_id = $userId",
            ("$id", id),
            ("$userId", userId)
        );

        delete.ExecuteNonQuery();

        return Results.NoContent();
    }
}
