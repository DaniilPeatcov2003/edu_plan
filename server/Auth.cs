using System.Buffers.Text;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace PamBackend;

public record RegisterRequest(
    string? Email,
    string? Password,
    string? Name,
    string? Specialty,
    int? StudyYear
);

public record LoginRequest(string? Email, string? Password);

public record UpdateProfileRequest(string? Name, string? Specialty, int? StudyYear);

public record User(
    long Id,
    string Email,
    string Name,
    string Specialty,
    int StudyYear
);

public static class Auth
{
    private static readonly string JwtSecret =
        Environment.GetEnvironmentVariable("JWT_SECRET") ?? "dev-secret-change-me";

    // -----------------------------------------------------------------------
    // Register
    // -----------------------------------------------------------------------

    public static IResult Register(RegisterRequest body)
    {
        var email = Errors.Trimmed(body.Email);
        var password = Errors.Trimmed(body.Password);
        var name = Errors.Trimmed(body.Name);
        var specialty = Errors.Trimmed(body.Specialty);

        if (email is null || !email.Contains('@'))
            return Errors.Validation("A valid email is required");

        if (password is null)
            return Errors.Validation("password is required");

        if (name is null)
            return Errors.Validation("name is required");

        if (specialty is null)
            return Errors.Validation("specialty is required");

        if (body.StudyYear is null || body.StudyYear < 1 || body.StudyYear > 6)
            return Errors.Validation("studyYear must be between 1 and 6");

        using var conn = Db.Open();

        using (var existing = conn.Cmd(
                   "SELECT id FROM users WHERE email = $email",
                   ("$email", email)))
        {
            if (existing.ExecuteScalar() is not null)
                return Errors.EmailTaken();
        }

        using (var insert = conn.Cmd(
                   """
                   INSERT INTO users
                   (email, password_hash, name, specialty, study_year, created_at)
                   VALUES
                   ($email, $hash, $name, $specialty, $studyYear, $createdAt)
                   """,
                   ("$email", email),
                   ("$hash", HashPassword(password)),
                   ("$name", name),
                   ("$specialty", specialty),
                   ("$studyYear", body.StudyYear.Value),
                   ("$createdAt", Db.NowIso())))
        {
            insert.ExecuteNonQuery();
        }

        var id = conn.LastInsertRowId();

        var user = new User(
            id,
            email,
            name,
            specialty,
            body.StudyYear.Value
        );

        return Results.Json(
            new { token = IssueToken(id), user },
            statusCode: 201
        );
    }

    // -----------------------------------------------------------------------
    // Login
    // -----------------------------------------------------------------------

    public static IResult Login(LoginRequest body)
    {
        var email = Errors.Trimmed(body.Email);
        var password = Errors.Trimmed(body.Password);

        if (email is null || password is null)
            return Errors.Unauthorized("Invalid email or password");

        using var conn = Db.Open();

        using var cmd = conn.Cmd(
            """
            SELECT id, email, name, password_hash, specialty, study_year
            FROM users
            WHERE email = $email
            """,
            ("$email", email));

        using var reader = cmd.ExecuteReader();

        if (!reader.Read())
            return Errors.Unauthorized("Invalid email or password");

        var userId = reader.GetInt64(0);
        var userEmail = reader.GetString(1);
        var userName = reader.GetString(2);
        var passwordHash = reader.GetString(3);
        var specialty = reader.GetString(4);
        var studyYear = reader.GetInt32(5);

        if (!VerifyPassword(password, passwordHash))
            return Errors.Unauthorized("Invalid email or password");

        var user = new User(
            userId,
            userEmail,
            userName,
            specialty,
            studyYear
        );

        return Results.Json(
            new { token = IssueToken(user.Id), user }
        );
    }

    // -----------------------------------------------------------------------
    // Current user
    // -----------------------------------------------------------------------

    public static IResult Me(HttpContext context)
    {
        using var conn = Db.Open();

        using var cmd = conn.Cmd(
            """
            SELECT id, email, name, specialty, study_year
            FROM users
            WHERE id = $id
            """,
            ("$id", CurrentUserId(context)));

        using var reader = cmd.ExecuteReader();

        if (!reader.Read())
            return Errors.Unauthorized();

        var user = new User(
            reader.GetInt64(0),
            reader.GetString(1),
            reader.GetString(2),
            reader.GetString(3),
            reader.GetInt32(4)
        );

        return Results.Json(user);
    }

    // -----------------------------------------------------------------------
    // Update current user profile
    // -----------------------------------------------------------------------

    public static IResult UpdateProfile(
        UpdateProfileRequest body,
        HttpContext context)
    {
        var name = Errors.Trimmed(body.Name);
        var specialty = Errors.Trimmed(body.Specialty);

        if (name is null)
            return Errors.Validation("name is required");

        if (specialty is null)
            return Errors.Validation("specialty is required");

        if (body.StudyYear is null ||
            body.StudyYear < 1 ||
            body.StudyYear > 6)
        {
            return Errors.Validation(
                "studyYear must be between 1 and 6");
        }

        var userId = CurrentUserId(context);

        using var conn = Db.Open();

        using var update = conn.Cmd(
            """
            UPDATE users
            SET name = $name,
                specialty = $specialty,
                study_year = $studyYear
            WHERE id = $id
            """,
            ("$name", name),
            ("$specialty", specialty),
            ("$studyYear", body.StudyYear.Value),
            ("$id", userId));

        var affectedRows = update.ExecuteNonQuery();

        if (affectedRows == 0)
            return Errors.Unauthorized();

        return Me(context);
    }

    // -----------------------------------------------------------------------
    // Delete current user account
    // -----------------------------------------------------------------------

    public static IResult DeleteAccount(HttpContext context)
    {
        var userId = CurrentUserId(context);
        var filePaths = new List<string>();

        using var conn = Db.Open();
        using var transaction = conn.BeginTransaction();

        try
        {
            // Получаем пути файлов текущего пользователя.
            using (var select = conn.CreateCommand())
            {
                select.Transaction = transaction;
                select.CommandText =
                    "SELECT path FROM files WHERE user_id = $userId";

                select.Parameters.AddWithValue("$userId", userId);

                using var reader = select.ExecuteReader();

                while (reader.Read())
                {
                    filePaths.Add(reader.GetString(0));
                }
            }

            // Удаляем связанные данные.
            foreach (var table in new[] { "tasks", "notes", "files", "courses" })
            {
                using var delete = conn.CreateCommand();
                delete.Transaction = transaction;
                delete.CommandText =
                    $"DELETE FROM {table} WHERE user_id = $userId";

                delete.Parameters.AddWithValue("$userId", userId);
                delete.ExecuteNonQuery();
            }

            // Удаляем сам аккаунт.
            using (var deleteUser = conn.CreateCommand())
            {
                deleteUser.Transaction = transaction;
                deleteUser.CommandText =
                    "DELETE FROM users WHERE id = $userId";

                deleteUser.Parameters.AddWithValue("$userId", userId);

                if (deleteUser.ExecuteNonQuery() == 0)
                {
                    transaction.Rollback();
                    return Errors.Unauthorized();
                }
            }

            transaction.Commit();
        }
        catch
        {
            transaction.Rollback();
            throw;
        }

        // После успешного удаления записей удаляем файлы с диска.
        foreach (var path in filePaths)
        {
            try
            {
                if (File.Exists(path))
                    File.Delete(path);
            }
            catch (IOException)
            {
                // Ошибка удаления файла не отменяет удаление аккаунта.
            }
            catch (UnauthorizedAccessException)
            {
                // Нет доступа к файлу.
            }
        }

        return Results.Ok(new { message = "Account deleted successfully" });
    }
    
    // -----------------------------------------------------------------------
    // Auth filter
    // -----------------------------------------------------------------------

    public static async ValueTask<object?> RequireAuth(
        EndpointFilterInvocationContext context,
        EndpointFilterDelegate next)
    {
        var header = context.HttpContext.Request.Headers.Authorization.ToString();

        if (!header.StartsWith("Bearer "))
            return Errors.Unauthorized();

        var userId = VerifyToken(header["Bearer ".Length..]);

        if (userId is null)
            return Errors.Unauthorized();

        context.HttpContext.Items["userId"] = userId.Value;

        return await next(context);
    }

    public static long CurrentUserId(HttpContext context) =>
        (long)context.Items["userId"]!;

    // -----------------------------------------------------------------------
    // JWT
    // -----------------------------------------------------------------------

    public static string IssueToken(long userId)
    {
        var header = B64Json(new { alg = "HS256", typ = "JWT" });

        var now = DateTimeOffset.UtcNow.ToUnixTimeSeconds();

        var payload = B64Json(new
        {
            sub = userId.ToString(),
            iat = now,
            exp = now + 7 * 24 * 60 * 60,
        });

        return $"{header}.{payload}.{Sign($"{header}.{payload}")}";
    }

    public static long? VerifyToken(string token)
    {
        var parts = token.Split('.');

        if (parts.Length != 3)
            return null;

        var expected = Sign($"{parts[0]}.{parts[1]}");

        if (!CryptographicOperations.FixedTimeEquals(
                Encoding.ASCII.GetBytes(expected),
                Encoding.ASCII.GetBytes(parts[2])))
        {
            return null;
        }

        try
        {
            var payload = JsonNode.Parse(
                Base64Url.DecodeFromChars(parts[1]))!.AsObject();

            var now = DateTimeOffset.UtcNow.ToUnixTimeSeconds();

            if (now >= payload["exp"]!.GetValue<long>())
                return null;

            return long.Parse(payload["sub"]!.GetValue<string>());
        }
        catch
        {
            return null;
        }
    }

    private static string B64Json(object data) =>
        Base64Url.EncodeToString(
            JsonSerializer.SerializeToUtf8Bytes(data));

    private static string Sign(string data) =>
        Base64Url.EncodeToString(
            HMACSHA256.HashData(
                Encoding.UTF8.GetBytes(JwtSecret),
                Encoding.UTF8.GetBytes(data)));

    // -----------------------------------------------------------------------
    // Password hashing
    // -----------------------------------------------------------------------

    private const int Iterations = 100_000;
    private const int HashBytes = 32;

    public static string HashPassword(string password)
    {
        var salt = RandomNumberGenerator.GetBytes(16);

        var hash = Rfc2898DeriveBytes.Pbkdf2(
            password,
            salt,
            Iterations,
            HashAlgorithmName.SHA256,
            HashBytes);

        return $"{Iterations}:{Convert.ToBase64String(salt)}:{Convert.ToBase64String(hash)}";
    }

    public static bool VerifyPassword(string password, string stored)
    {
        var parts = stored.Split(':');

        if (parts.Length != 3 ||
            !int.TryParse(parts[0], out var iterations))
            return false;

        try
        {
            var salt = Convert.FromBase64String(parts[1]);
            var expected = Convert.FromBase64String(parts[2]);

            var hash = Rfc2898DeriveBytes.Pbkdf2(
                password,
                salt,
                iterations,
                HashAlgorithmName.SHA256,
                expected.Length);

            return CryptographicOperations.FixedTimeEquals(
                hash,
                expected);
        }
        catch
        {
            return false;
        }
    }
}
