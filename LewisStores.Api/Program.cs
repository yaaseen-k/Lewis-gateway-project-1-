using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Text;
using System.Text.Json.Serialization;
using System.Reflection;
using LewisStores.Api.Data;
using LewisStores.Api.Swagger;
using Swashbuckle.AspNetCore.SwaggerUI;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles;
    });

// Configure DbContext with SQL Server
var defaultConnection = "Server=localhost;Database=LewisStoresDb;Trusted_Connection=true;Encrypt=false;";
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? Environment.GetEnvironmentVariable("CONNECTION_STRINGS__DEFAULT_CONNECTION")
    ?? defaultConnection;

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(connectionString, sqlServerOptionsAction =>
    {
        sqlServerOptionsAction.MigrationsAssembly("LewisStores.Api");
    }));

// Configure CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll",
        policy =>
        {
            policy.AllowAnyOrigin()
                  .AllowAnyMethod()
                  .AllowAnyHeader();
        });
});

// Configure Mock JWT Authentication
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = "LewisStoresMockIssuer",
            ValidAudience = "LewisStoresMockAudience",
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes("ThisIsAMockSuperSecretKeyForLewisStoresApisThatIsAtLeast32Bytes"))
        };
    });

// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "Lewis Stores Commerce Platform API",
        Version = "v1.0",
        Description = """
            Enterprise API reference for the Lewis Stores digital commerce platform.

            This specification provides documentation for catalog operations, customer identity, checkout, orders, returns, support workflows, and QA training controls.

            ### Platform Capabilities
            - Product and category discovery for merchandising and storefront experiences
            - Authentication, profile management, and role-based access controls
            - Order lifecycle management, payment methods, and checkout orchestration
            - Returns/refunds and customer support case operations
            - QA scenario packs, feature flags, and audit telemetry for quality engineering exercises

            ### Security and Access
            Most customer and operational endpoints require JWT bearer authentication. Obtain an access token through `POST /api/Auth/login`, then authorize requests via the `Authorization: Bearer <token>` header.

            ### Governance Notes
            This API is intended for internal engineering, training, and controlled testing environments. Behaviour may intentionally include configurable defect scenarios for quality-engineering labs.
            """,
        TermsOfService = new Uri("https://lewisstores.local/terms/api"),
        Contact = new OpenApiContact
        {
            Name = "Lewis Stores Platform Engineering",
            Email = "platform.api@lewisstores.local",
            Url = new Uri("https://lewisstores.local/engineering")
        },
        License = new OpenApiLicense
        {
            Name = "Lewis Stores Internal Platform License",
            Url = new Uri("https://lewisstores.local/legal/internal-platform-license")
        }
    });

    c.CustomSchemaIds(type => type.FullName?.Replace("+", "."));
    c.SupportNonNullableReferenceTypes();

    var xmlFile = $"{Assembly.GetExecutingAssembly().GetName().Name}.xml";
    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
    if (File.Exists(xmlPath))
    {
        c.IncludeXmlComments(xmlPath, includeControllerXmlComments: true);
    }

    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT bearer authentication.\n\nEnter only the token value below; Swagger UI will prepend 'Bearer '.",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT"
    });

    c.OperationFilter<AuthorizeCheckOperationFilter>();

    c.TagActionsBy(api =>
    {
        if (api.GroupName is not null)
        {
            return new[] { api.GroupName };
        }

        if (api.ActionDescriptor.RouteValues.TryGetValue("controller", out var controllerName) && !string.IsNullOrWhiteSpace(controllerName))
        {
            return new[] { controllerName };
        }

        return new[] { "Endpoints" };
    });

    c.OrderActionsBy(api => $"{api.GroupName}_{api.HttpMethod}_{api.RelativePath}");
});

var app = builder.Build();

var resetDatabaseOnStart = builder.Configuration.GetValue<bool>("ResetDatabaseOnStart")
    || string.Equals(Environment.GetEnvironmentVariable("RESET_DATABASE_ON_START"), "true", StringComparison.OrdinalIgnoreCase);

var renderPort = Environment.GetEnvironmentVariable("PORT");
if (!string.IsNullOrWhiteSpace(renderPort))
{
    app.Urls.Add($"http://0.0.0.0:{renderPort}");
}

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment() || true) // Always show swagger for this mock app
{
    app.UseSwagger(c =>
    {
        c.RouteTemplate = "docs/{documentName}/openapi.json";
    });

    app.UseStaticFiles();

    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/docs/v1/openapi.json", "Lewis Stores Commerce Platform API v1.0");
        c.RoutePrefix = "docs";
        c.DocumentTitle = "Lewis Stores Commerce Platform | API Reference";
        c.DocExpansion(DocExpansion.List);
        c.DefaultModelsExpandDepth(-1);
        c.EnableDeepLinking();
        c.EnableFilter();
        c.DisplayRequestDuration();
        c.EnablePersistAuthorization();
        c.InjectStylesheet("/swagger-ui/custom.css");
        c.InjectJavascript("/swagger-ui/custom.js", "text/javascript");
    });
}

app.UseHttpsRedirection();

app.UseCors("AllowAll");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

// Create and initialize database
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

    try
    {
        if (resetDatabaseOnStart)
        {
            db.Database.EnsureDeleted();
            System.Console.WriteLine("Database deleted for reset.");
        }

        // Ensure database and schema are created
        if (!db.Database.CanConnect())
        {
            db.Database.EnsureCreated();
            System.Console.WriteLine("Database created successfully.");
        }
        else
        {
            // Database exists, ensure tables are created
            db.Database.EnsureCreated();
            System.Console.WriteLine("Database already exists. Schema verified.");
        }

        EnsureCompatibilitySchema(db);

        System.Console.WriteLine("Database initialization completed successfully.");
    }
    catch (Exception ex)
    {
        System.Console.WriteLine($"Error during database initialization: {ex.Message}");
        throw;
    }
}

app.Run();

static void EnsureCompatibilitySchema(AppDbContext db)
{
    db.Database.ExecuteSqlRaw(
        """
        IF OBJECT_ID(N'[dbo].[Deliveries]', N'U') IS NULL
        BEGIN
            CREATE TABLE [dbo].[Deliveries] (
                [Id] INT IDENTITY(1,1) NOT NULL,
                [OrderId] NVARCHAR(450) NOT NULL,
                [UserId] NVARCHAR(450) NOT NULL,
                [Status] NVARCHAR(50) NOT NULL CONSTRAINT [DF_Deliveries_Status] DEFAULT N'Processing',
                [Carrier] NVARCHAR(100) NOT NULL,
                [TrackingNumber] NVARCHAR(100) NOT NULL,
                [Origin] NVARCHAR(255) NOT NULL,
                [Destination] NVARCHAR(255) NOT NULL,
                [CurrentLocation] NVARCHAR(255) NOT NULL,
                [ShippedAtUtc] DATETIME2 NULL,
                [EstimatedDeliveryAtUtc] DATETIME2 NOT NULL,
                [DeliveredAtUtc] DATETIME2 NULL,
                [UpdatedAtUtc] DATETIME2 NOT NULL CONSTRAINT [DF_Deliveries_UpdatedAtUtc] DEFAULT GETUTCDATE(),
                CONSTRAINT [PK_Deliveries] PRIMARY KEY ([Id]),
                CONSTRAINT [FK_Deliveries_Orders] FOREIGN KEY ([OrderId]) REFERENCES [dbo].[Orders]([Id]),
                CONSTRAINT [FK_Deliveries_Users] FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users]([Id])
            );

            CREATE INDEX [IX_Deliveries_OrderId] ON [dbo].[Deliveries]([OrderId]);
            CREATE INDEX [IX_Deliveries_UserId] ON [dbo].[Deliveries]([UserId]);
            CREATE INDEX [IX_Deliveries_Status] ON [dbo].[Deliveries]([Status]);
            CREATE INDEX [IX_Deliveries_UpdatedAtUtc] ON [dbo].[Deliveries]([UpdatedAtUtc]);
        END

        IF OBJECT_ID(N'[dbo].[Categories]', N'U') IS NOT NULL AND COL_LENGTH(N'[dbo].[Products]', N'CategoryId') IS NULL
        BEGIN
            ALTER TABLE [dbo].[Products] ADD [CategoryId] NVARCHAR(450) NULL;
        END
        """);

    db.Database.ExecuteSqlRaw(
        """
        IF OBJECT_ID(N'[dbo].[Categories]', N'U') IS NOT NULL AND COL_LENGTH(N'[dbo].[Products]', N'CategoryId') IS NOT NULL
        BEGIN
            ;WITH DistinctCategories AS
            (
                SELECT DISTINCT LTRIM(RTRIM([Category])) AS [CategoryName]
                FROM [dbo].[Products]
                WHERE [Category] IS NOT NULL AND LTRIM(RTRIM([Category])) <> ''
            )
            INSERT INTO [dbo].[Categories] ([Id], [Name], [Description], [To], [Tone])
            SELECT
                CONCAT(N'cat-', REPLACE(CONVERT(NVARCHAR(36), NEWID()), N'-', N'')),
                dc.[CategoryName],
                N'',
                N'/products',
                CONCAT(N'category-', LOWER(REPLACE(REPLACE(dc.[CategoryName], N' ', N'-'), N'&', N'and')))
            FROM DistinctCategories dc
            WHERE NOT EXISTS (
                SELECT 1
                FROM [dbo].[Categories] c
                WHERE c.[Name] = dc.[CategoryName]
            );

            UPDATE p
            SET p.[CategoryId] = c.[Id]
            FROM [dbo].[Products] p
            INNER JOIN [dbo].[Categories] c ON c.[Name] = p.[Category]
            WHERE p.[CategoryId] IS NULL OR p.[CategoryId] <> c.[Id];

            IF EXISTS (SELECT 1 FROM [dbo].[Products] WHERE [CategoryId] IS NULL)
            BEGIN
                THROW 51000, 'Unable to backfill product categories because one or more products do not match a category row.', 1;
            END

            IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Products]') AND name = N'CategoryId' AND is_nullable = 1)
            BEGIN
                ALTER TABLE [dbo].[Products] ALTER COLUMN [CategoryId] NVARCHAR(450) NOT NULL;
            END

            IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Products_CategoryId' AND object_id = OBJECT_ID(N'[dbo].[Products]'))
            BEGIN
                CREATE INDEX [IX_Products_CategoryId] ON [dbo].[Products]([CategoryId]);
            END

            IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Products_Categories')
            BEGIN
                ALTER TABLE [dbo].[Products] WITH CHECK ADD CONSTRAINT [FK_Products_Categories] FOREIGN KEY ([CategoryId]) REFERENCES [dbo].[Categories]([Id]);
            END
        END
        """);
}
