// PAM backend template - .NET (Minimal API) port.
//
// Start:  dotnet run
// Env:    PORT (default 8080), JWT_SECRET (default dev-secret-change-me)

using PamBackend;

var port = Environment.GetEnvironmentVariable("PORT") ?? "8080";

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddCors(options => options.AddDefaultPolicy(policy =>
    policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader()));

builder.Services.Configure<RouteHandlerOptions>(o =>
    o.ThrowOnBadRequest = true);

var app = builder.Build();

app.Use(Errors.HandleExceptions);
app.UseCors();

Db.Init("app.db");
Files.InitStorage("uploads");

app.MapGet("/health", () =>
    Results.Json(new { status = "ok" }));

// Authentication
app.MapPost("/auth/register", Auth.Register);
app.MapPost("/auth/login", Auth.Login);

app.MapGet("/me", Auth.Me)
    .AddEndpointFilter(Auth.RequireAuth);

app.MapPut("/me", Auth.UpdateProfile)
    .AddEndpointFilter(Auth.RequireAuth);

app.MapDelete("/me", Auth.DeleteAccount)
    .AddEndpointFilter(Auth.RequireAuth);

// Notes: example CRUD entity
var notes = app.MapGroup("/notes")
    .AddEndpointFilter(Auth.RequireAuth);

notes.MapGet("", Notes.List);
notes.MapPost("", Notes.Create);
notes.MapGet("/{id:long}", Notes.GetOne);
notes.MapPut("/{id:long}", Notes.Update);
notes.MapDelete("/{id:long}", Notes.Delete);

// Tasks: EduPlan entity
var tasks = app.MapGroup("/tasks")
    .AddEndpointFilter(Auth.RequireAuth);

tasks.MapGet("", Tasks.List);
tasks.MapPost("", Tasks.Create);
tasks.MapGet("/{id:long}", Tasks.GetOne);
tasks.MapPut("/{id:long}", Tasks.Update);
tasks.MapDelete("/{id:long}", Tasks.Delete);

tasks.MapGet("/{id:long}/files", TaskFiles.List);

tasks.MapPost(
    "/{id:long}/files/{fileId:long}",
    TaskFiles.Attach
);

tasks.MapDelete(
    "/{id:long}/files/{fileId:long}",
    TaskFiles.Detach
);

// Courses
var courses = app.MapGroup("/courses")
    .AddEndpointFilter(Auth.RequireAuth);

courses.MapGet("", Courses.List);
courses.MapPost("", Courses.Create);
courses.MapGet("/{id:long}", Courses.GetOne);
courses.MapPut("/{id:long}", Courses.Update);
courses.MapDelete("/{id:long}", Courses.Delete);

// Files
app.MapPost("/files", Files.Upload)
    .AddEndpointFilter(Auth.RequireAuth);

app.MapGet("/files/{id:long}", Files.Download)
    .AddEndpointFilter(Auth.RequireAuth);

// Unknown routes
app.MapFallback(() =>
    Errors.NotFound("Route not found"));

app.Run($"http://0.0.0.0:{port}");

