
namespace PamBackend;

public static class TaskFiles
{
    // GET /tasks/{id}/files
    public static IResult List(HttpContext context, long id)
    {
        var userId = Auth.CurrentUserId(context);

        using var conn = Db.Open();

        // Проверяем, что задание принадлежит пользователю.
        using (var check = conn.Cmd(
            "SELECT 1 FROM tasks WHERE id = $id AND user_id = $userId",
            ("$id", id),
            ("$userId", userId)))
        {
            if (check.ExecuteScalar() is null)
                return Errors.NotFound("Task not found");
        }

        var items = new List<object>();

        using (var cmd = conn.Cmd(
            """
            SELECT f.id, f.name, f.size, f.mime_type
            FROM task_files tf
            JOIN files f ON f.id = tf.file_id
            JOIN tasks t ON t.id = tf.task_id
            WHERE t.id = $taskId
              AND t.user_id = $userId
              AND f.user_id = $userId
            ORDER BY tf.created_at DESC
            """,
            ("$taskId", id),
            ("$userId", userId)))
        using (var reader = cmd.ExecuteReader())
        {
            while (reader.Read())
            {
                var fileId = reader.GetInt64(0);

                items.Add(new
                {
                    id = fileId,
                    name = reader.GetString(1),
                    size = reader.GetInt64(2),
                    mimeType = reader.GetString(3),
                    url = $"/files/{fileId}"
                });
            }
        }

        return Results.Json(items);
    }

    // POST /tasks/{id}/files/{fileId}
    public static IResult Attach(
        HttpContext context,
        long id,
        long fileId)
    {
        var userId = Auth.CurrentUserId(context);

        using var conn = Db.Open();

        // Проверяем владельца задания.
        using (var checkTask = conn.Cmd(
            "SELECT 1 FROM tasks WHERE id = $id AND user_id = $userId",
            ("$id", id),
            ("$userId", userId)))
        {
            if (checkTask.ExecuteScalar() is null)
                return Errors.NotFound("Task not found");
        }

        // Проверяем владельца файла.
        using (var checkFile = conn.Cmd(
            "SELECT 1 FROM files WHERE id = $fileId AND user_id = $userId",
            ("$fileId", fileId),
            ("$userId", userId)))
        {
            if (checkFile.ExecuteScalar() is null)
                return Errors.NotFound("File not found");
        }

        using (var insert = conn.Cmd(
            """
            INSERT OR IGNORE INTO task_files
            (task_id, file_id, created_at)
            VALUES ($taskId, $fileId, $createdAt)
            """,
            ("$taskId", id),
            ("$fileId", fileId),
            ("$createdAt", Db.NowIso())))
        {
            insert.ExecuteNonQuery();
        }

        return Results.NoContent();
    }

    // DELETE /tasks/{id}/files/{fileId}
    public static IResult Detach(
        HttpContext context,
        long id,
        long fileId)
    {
        var userId = Auth.CurrentUserId(context);

        using var conn = Db.Open();

        // Проверяем, что задание принадлежит пользователю.
        using (var checkTask = conn.Cmd(
            "SELECT 1 FROM tasks WHERE id = $id AND user_id = $userId",
            ("$id", id),
            ("$userId", userId)))
        {
            if (checkTask.ExecuteScalar() is null)
                return Errors.NotFound("Task not found");
        }

        // Удаляем только связь между заданием и файлом.
        using var delete = conn.Cmd(
            """
            DELETE FROM task_files
            WHERE task_id = $taskId
              AND file_id = $fileId
            """,
            ("$taskId", id),
            ("$fileId", fileId));

        if (delete.ExecuteNonQuery() == 0)
            return Errors.NotFound("Attachment not found");

        return Results.NoContent();
    }
}
