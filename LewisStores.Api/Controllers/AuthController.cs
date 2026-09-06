using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using LewisStores.Api.Data;
using Microsoft.EntityFrameworkCore;

namespace LewisStores.Api.Controllers
{
    /// <summary>
    /// Handles authentication flows for client applications.
    /// </summary>
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly AppDbContext _context;

        public AuthController(AppDbContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Request payload for login operations.
        /// </summary>
        public class LoginRequest
        {
            /// <summary>
            /// User email used for sign-in.
            /// </summary>
            public string Email { get; set; } = string.Empty;

            /// <summary>
            /// User password. In this mock API this is accepted for testing.
            /// </summary>
            public string Password { get; set; } = string.Empty;
        }

        /// <summary>
        /// Request payload for registering a customer account.
        /// </summary>
        public class RegisterRequest
        {
            public string FullName { get; set; } = string.Empty;
            public string Email { get; set; } = string.Empty;
            public string Password { get; set; } = string.Empty;
            public string Phone { get; set; } = string.Empty;
            public string Address { get; set; } = string.Empty;
        }

        /// <summary>
        /// Request payload for updating the authenticated user's profile.
        /// </summary>
        public class UpdateProfileRequest
        {
            public string FullName { get; set; } = string.Empty;
            public string Phone { get; set; } = string.Empty;
            public string Address { get; set; } = string.Empty;
        }

        /// <summary>
        /// Authenticates a user and returns a JWT token for authorized calls.
        /// </summary>
        /// <remarks>
        /// In this mock implementation, users are auto-created when the email does not exist.
        /// </remarks>
        /// <param name="request">Login credentials.</param>
        /// <returns>JWT token and user profile details.</returns>
        [HttpPost("login")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))
            {
                return BadRequest(new { Message = "Email and password are required." });
            }

            var email = request.Email.Trim();
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email.ToLower() == email.ToLower());
            if (user == null || user.Password != request.Password)
            {
                await AddAuditAsync("auth.login.failed", null, "Warning", $"{{\"email\":\"{email}\"}}");
                return Unauthorized(new { Message = "Invalid credentials." });
            }

            var token = CreateToken(user.Id, user.Email, user.Role);
            await AddAuditAsync("auth.login.success", user.Id, "Info", "{\"source\":\"api\"}");

            return Ok(new
            {
                Token = token,
                User = new { user.Id, user.Email, user.Role, user.FullName, user.Phone, user.Address }
            });
        }

        /// <summary>
        /// Registers a new customer account.
        /// </summary>
        [HttpPost("register")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status409Conflict)]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password) || string.IsNullOrWhiteSpace(request.FullName))
            {
                return BadRequest(new { Message = "Full name, email, and password are required." });
            }

            var isCaseSensitiveDefectEnabled = await IsFlagEnabledAsync("auth_email_case_sensitive");
            var email = request.Email.Trim();

            var existing = isCaseSensitiveDefectEnabled
                ? await _context.Users.AnyAsync(u => u.Email == email)
                : await _context.Users.AnyAsync(u => u.Email.ToLower() == email.ToLower());

            if (existing)
            {
                return Conflict(new { Message = "An account with this email already exists." });
            }

            var user = new Models.User
            {
                Id = Guid.NewGuid().ToString("N"),
                Email = email,
                Password = request.Password,
                Role = "Customer",
                FullName = request.FullName.Trim(),
                Phone = request.Phone.Trim(),
                Address = request.Address.Trim()
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();
            await AddAuditAsync("auth.register.success", user.Id, "Info", "{\"source\":\"api\"}");

            var token = CreateToken(user.Id, user.Email, user.Role);

            return Ok(new
            {
                Token = token,
                User = new { user.Id, user.Email, user.Role, user.FullName, user.Phone, user.Address }
            });
        }

        /// <summary>
        /// Returns the authenticated user's profile.
        /// </summary>
        [Authorize]
        [HttpGet("me")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> Me()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
            if (user == null)
            {
                return Unauthorized();
            }

            return Ok(new { user.Id, user.Email, user.Role, user.FullName, user.Phone, user.Address });
        }

        /// <summary>
        /// Updates the authenticated user's profile details.
        /// </summary>
        [Authorize]
        [HttpPut("me")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> UpdateMe([FromBody] UpdateProfileRequest request)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
            if (user == null)
            {
                return Unauthorized();
            }

            user.FullName = request.FullName?.Trim() ?? string.Empty;
            user.Phone = request.Phone?.Trim() ?? string.Empty;
            user.Address = request.Address?.Trim() ?? string.Empty;

            await _context.SaveChangesAsync();
            await AddAuditAsync("profile.updated", user.Id, "Info", "{\"source\":\"api\"}");

            return Ok(new { user.Id, user.Email, user.Role, user.FullName, user.Phone, user.Address });
        }

        private async Task<bool> IsFlagEnabledAsync(string key)
        {
            return await _context.QaFeatureFlags
                .Where(f => f.Key == key)
                .Select(f => f.IsEnabled)
                .FirstOrDefaultAsync();
        }

        private async Task AddAuditAsync(string eventType, string? userId, string severity, string details)
        {
            var verboseAudit = await IsFlagEnabledAsync("audit_verbose_events");
            if (!verboseAudit)
            {
                return;
            }

            _context.AuditLogs.Add(new Models.AuditLog
            {
                TimestampUtc = DateTime.UtcNow,
                EventType = eventType,
                UserId = userId,
                Severity = severity,
                Details = details
            });

            await _context.SaveChangesAsync();
        }

        private static string CreateToken(string userId, string email, string role)
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.UTF8.GetBytes("ThisIsAMockSuperSecretKeyForLewisStoresApisThatIsAtLeast32Bytes");
            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(new[]
                {
                    new Claim(ClaimTypes.NameIdentifier, userId),
                    new Claim(ClaimTypes.Email, email),
                    new Claim(ClaimTypes.Role, role)
                }),
                Expires = DateTime.UtcNow.AddDays(7),
                SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature),
                Issuer = "LewisStoresMockIssuer",
                Audience = "LewisStoresMockAudience"
            };
            var token = tokenHandler.CreateToken(tokenDescriptor);
            return tokenHandler.WriteToken(token);
        }
    }
}
