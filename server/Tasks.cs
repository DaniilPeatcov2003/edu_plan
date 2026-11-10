using Microsoft.Data.Sqlite;

namespace PamBackend;

public record TaskItem(
    long Id,
    string Title,
    string Course,
    long? CourseId,
    string Deadline,
    string Status,
    string Priority,
    string CreatedAt
);

public record TaskInput(
    string? Title,
    string? Course,
    string? Deadline,
    string? Status,
    string? Priority,
    long? CourseId = null
);

public static class Tasks
{
    private static TaskItem ReadTask(SqliteDataReader reader) => new(
        reader.GetInt64(0),
        reader.GetString(1),
        reader.GetString(2),
        reader.IsDBNull(3) ? null : reader.GetInt64(3),
        reader.GetString(4),
        reader.GetString(5),
        reader.GetString(6),
        reader.GetString(7)
    );

    private const string SelectTaskSql = """
        SELECT id, title, course, course_id,
               deadline, status, priority, created_at
        FROM tasks
        """;

    private static TaskItem? Find(
        SqliteConnection conn,
        long userId,
        long id)
    {
        using var cmd = conn.Cmd(
            SelectTaskSql + "\n" + """
                WHERE id = $id AND user_id = $userId
                """,
            ("$id", id),
            ("$userId", userId)
        );

        using var reader = cmd.ExecuteReader();
        return reader.Read() ? ReadTask(reader) : null;
    }

    private static (long Id, string Name)? FindCourse(
        SqliteConnection conn,
        long userId,
        long? courseId,
        string? courseName)
    {
        using var cmd = conn.Cmd(
            """
            SELECT id, name
            FROM courses
            WHERE user_id = $userId
              AND (
                  ($courseId IS NOT NULL AND id = $courseId)
                  OR
                  ($courseId IS NULL AND name = $courseName)
              )
            ORDER BY id
            LIMIT 1
            """,
            ("$userId", userId),
            ("$courseId", courseId),
            ("$courseName", courseName)
        );

        using var reader = cmd.ExecuteReader();

        return reader.Read()
            ? (reader.GetInt64(0), reader.GetString(1))
            : null;
    }

    public static IResult List(
        HttpContext context,
        int page = 1,
        int limit = 20,
        string search = "")
    {
        page = Math.Max(page, 1);
        limit = Math.Clamp(limit, 1, 100);

        var userId = Auth.CurrentUserId(context);
        var pattern = $"%{search}%";

        const string filter = """
            user_id = $userId
            AND (title LIKE $pattern OR course LIKE $pattern)
            """;

        using var conn = Db.Open();

        long total;

        using (var count = conn.Cmd(
            $"SELECT COUNT(*) FROM tasks WHERE {filter}",
            ("$userId", userId),
            ("$pattern", pattern)))
        {
            total = (long)count.ExecuteScalar()!;
        }

        var items = new List<TaskItem>();

        var sql = SelectTaskSql + "\n" + $"""
            WHERE {filter}
            ORDER BY id DESC
            LIMIT $limit OFFSET $offset
            """;

        using (var cmd = conn.Cmd(
            sql,
            ("$userId", userId),
            ("$pattern", pattern),
            ("$limit", limit),
            ("$offset", (page - 1) * limit)))
        using (var reader = cmd.ExecuteReader())
        {
            while (reader.Read())
            {
                items.Add(ReadTask(reader));
            }
        }

        return Results.Json(new { items, page, limit, total });
    }

    public static IResult Create(
        HttpContext context,
        TaskInput input)
    {
        var title = Errors.Trimmed(input.Title);
        var courseName = Errors.Trimmed(input.Course);
        var deadline = Errors.Trimmed(input.Deadline);
        var status = Errors.Trimmed(input.Status);
        var priority = Errors.Trimmed(input.Priority);

        if (title is null || deadline is null ||
            status is null || priority is null ||
            (input.CourseId is null && courseName is null))
        {
            return Errors.Validation(
                "title, course, deadline, status and priority are required"
            );
        }

        var userId = Auth.CurrentUserId(context);

        using var conn = Db.Open();

        var course = FindCourse(
            conn, userId, input.CourseId, courseName
        );

        if (course is null)
            return Errors.Validation("Selected course not found");

        using (var insert = conn.Cmd(
            """
            INSERT INTO tasks
            (user_id, title, course, course_id,
             deadline, status, priority, created_at)
            VALUES
            ($userId, $title, $course, $courseId,
             $deadline, $status, $priority, $createdAt)
            """,
            ("$userId", userId),
            ("$title", title),
            ("$course", course.Value.Name),
            ("$courseId", course.Value.Id),
            ("$deadline", deadline),
            ("$status", status),
            ("$priority", priority),
            ("$createdAt", Db.NowIso())))
        {
            insert.ExecuteNonQuery();
        }

        var task = Find(conn, userId, conn.LastInsertRowId())!;

        return Results.Created($"/tasks/{task.Id}", task);
    }

    public static IResult GetOne(HttpContext context, long id)
    {
        using var conn = Db.Open();

        var task = Find(conn, Auth.CurrentUserId(context), id);

        return task is null
            ? Errors.NotFound("Task not found")
            : Results.Json(task);
    }

    public static IResult Update(
        HttpContext context,
        long id,
        TaskInput input)
    {
        var userId = Auth.CurrentUserId(context);

        using var conn = Db.Open();

        if (Find(conn, userId, id) is null)
            return Errors.NotFound("Task not found");

        var title = Errors.Trimmed(input.Title);
        var courseName = Errors.Trimmed(input.Course);
        var deadline = Errors.Trimmed(input.Deadline);
        var status = Errors.Trimmed(input.Status);
        var priority = Errors.Trimmed(input.Priority);

        if (title is null || deadline is null ||
            status is null || priority is null ||
            (input.CourseId is null && courseName is null))
        {
            return Errors.Validation(
                "title, course, deadline, status and priority are required"
            );
        }

        var course = FindCourse(
            conn, userId, input.CourseId, courseName
        );

        if (course is null)
            return Errors.Validation("Selected course not found");

        using (var update = conn.Cmd(
            """
            UPDATE tasks
            SET title = $title,
                course = $course,
                course_id = $courseId,
                deadline = $deadline,
                status = $status,
                priority = $priority
            WHERE id = $id AND user_id = $userId
            """,
            ("$title", title),
            ("$course", course.Value.Name),
            ("$courseId", course.Value.Id),
            ("$deadline", deadline),
            ("$status", status),
            ("$priority", priority),
            ("$id", id),
            ("$userId", userId)))
        {
            update.ExecuteNonQuery();
        }

        return Results.Json(Find(conn, userId, id)!);
    }

    public static IResult Delete(HttpContext context, long id)
    {
        var userId = Auth.CurrentUserId(context);

        using var conn = Db.Open();

        if (Find(conn, userId, id) is null)
            return Errors.NotFound("Task not found");

        using var delete = conn.Cmd(
            "DELETE FROM tasks WHERE id = $id AND user_id = $userId",
            ("$id", id),
            ("$userId", userId)
        );

        delete.ExecuteNonQuery();

        return Results.NoContent();
    }
}
