using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using api.Data;
using api.Interfaces;
using api.Models;
using api.Respository;
using api.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;
using Microsoft.OpenApi.Models;
//using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// Add controllers
builder.Services.AddControllers();

// ─── SWAGGER WITH JWT AUTHENTICATION ───
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    // WHY: This adds the "Authorize" button (lock icon) in Swagger UI.
    // Without it, Swagger cannot send the Bearer token with requests.
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Enter: Bearer YOUR_JWT_TOKEN_HERE"
    });

    // WHY: This applies the security requirement to ALL endpoints.
    // The lock icon appears on every endpoint in Swagger.
    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

// WHY: NewtonsoftJson prevents infinite loops when serializing entities
// with navigation properties (Product.User → User.Products → Product.User...).
builder.Services.AddControllers().AddNewtonsoftJson(options =>
{
    options.SerializerSettings.ReferenceLoopHandling = Newtonsoft.Json.ReferenceLoopHandling.Ignore;
});

// ─── DATABASE CONTEXT ───
builder.Services.AddDbContext<ApplicationDBContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// ─── IDENTITY CONFIGURATION ───
// WHY: AddIdentity<AppUser, IdentityRole> uses string keys by default (Guid).
// This matches your JWT: "sub": "2133fc5e-e529-4912-87f9-87c9447aafeb"
builder.Services.AddIdentity<AppUser, IdentityRole>(options =>
{
    options.Password.RequireDigit = true;
    options.Password.RequireLowercase = true;
    options.Password.RequireUppercase = true;
    options.Password.RequireNonAlphanumeric = false;
    options.Password.RequiredLength = 6;
    options.Password.RequiredUniqueChars = 4;

    // Lockout settings
    options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(15);
    options.Lockout.MaxFailedAccessAttempts = 5;

    // User settings
    options.User.RequireUniqueEmail = true;
})
.AddEntityFrameworkStores<ApplicationDBContext>()
.AddDefaultTokenProviders();

// ─── JWT AUTHENTICATION ───
// CRITICAL FIX: Must specify DefaultScheme or ASP.NET Core falls back to cookies.
builder.Services.AddAuthentication(options =>
{
    // WHY: DefaultAuthenticateScheme tells [Authorize] WHICH auth system to use.
    // Without this, ASP.NET Core tries cookie authentication first,
    // doesn't find a cookie, and redirects to /Account/Login.
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidAudience = builder.Configuration["Jwt:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]!)),
        ClockSkew = TimeSpan.Zero,

        // CRITICAL FIX: NameClaimType determines which claim contains the User ID.
        // Your JWT has: "sub": "2133fc5e-..." (the user ID)
        // JwtRegisteredClaimNames.Sub maps to ClaimTypes.NameIdentifier internally.
        // We MUST tell ASP.NET Core to read 'sub' as the user identifier.
        NameClaimType = ClaimTypes.NameIdentifier,  // WAS: JwtRegisteredClaimNames.Name (WRONG!)

        RoleClaimType = ClaimTypes.Role
    };

    options.Events = new JwtBearerEvents
    {
        OnAuthenticationFailed = context =>
        {
            if (context.Exception is SecurityTokenExpiredException)
            {
                context.Response.Headers.Append("Token-Expired", "true");
            }
            return Task.CompletedTask;
        },

        // WHY: Log authentication failures during development.
        // Remove this in production.
        OnChallenge = context =>
        {
            // Prevent redirect to login page for API requests.
            // Return 401 JSON instead.
            context.HandleResponse();
            context.Response.StatusCode = 401;
            context.Response.ContentType = "application/json";
            return context.Response.WriteAsync("{\"message\":\"Unauthorized\"}");
        }
    };
});

// WHY: AddAuthorization enables the [Authorize] attribute.
// Without this, [Authorize] does nothing.
builder.Services.AddAuthorization();

// ─── DEPENDENCY INJECTION ───
builder.Services.AddScoped<IProductRespository, ProductRespository>();
builder.Services.AddScoped<IUserRespository, UserRespository>();
builder.Services.AddScoped<ITokenService, TokenService>();

var app = builder.Build();

// ─── MIDDLEWARE PIPELINE (ORDER MATTERS!) ───
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

// CRITICAL ORDER: Authentication BEFORE Authorization.
// Authentication figures out WHO you are.
// Authorization figures out WHAT you're allowed to do.
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();