using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using LewisStores.Api.Data;
using LewisStores.Api.Models;

namespace LewisStores.Api.Controllers
{
    /// <summary>
    /// Handles support case creation and role-based support operations.
    /// </summary>
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class SupportCasesController : ControllerBase
    {
        private readonly AppDbContext _context;

        public SupportCasesController(AppDbContext context)
        {
            _context = context;
        }

        public class CreateSupportCaseRequest
        {
            public string? OrderId { get; set; }
            public string Subject { get; set; } = string.Empty;
            public string Description { get; set; } = string.Empty;
            public string Priority { get; set; } = "Normal";
        }

        public class AssignSupportCaseRequest
        {
            public string AssignedToUserId { get; set; } = string.Empty;
        }

        public class UpdateSupportCaseStatusRequest
        {
            public string Status { get; set; } = string.Empty;
        }

        /// <summary>
        /// Lists support cases. Staff roles can view all; customers only see their own.
        /// </summary>
        [HttpGet]
        [ProducesResponseType(typeof(IEnumerable<SupportCase>), StatusCodes.Status200OK)]
        public async Task<ActionResult<IEnumerable<SupportCase>>> GetSupportCases([FromQuery] string? status = null)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            var isStaff = User.IsInRole("Admin") || User.IsInRole("Manager") || User.IsInRole("Support") || User.IsInRole("QaTester");
            var query = _context.SupportCases.AsQueryable();
            if (!isStaff)
            {
                query = query.Where(c => c.UserId == userId);
            }

            if (!string.IsNullOrWhiteSpace(status))
            {
                query = query.Where(c => c.Status == status);
            }

            var items = await query.OrderByDescending(c => c.UpdatedAtUtc).ToListAsync();
            return items;
        }

        /// <summary>
        /// Creates a support case for the authenticated user.
        /// </summary>
        [HttpPost]
        [ProducesResponseType(typeof(SupportCase), StatusCodes.Status201Created)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<ActionResult<SupportCase>> CreateSupportCase([FromBody] CreateSupportCaseRequest request)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            if (string.IsNullOrWhiteSpace(request.Subject) || string.IsNullOrWhiteSpace(request.Description))
            {
                return BadRequest(new { Message = "Subject and description are required." });
            }

            var entity = new SupportCase
            {
                UserId = userId,
                OrderId = string.IsNullOrWhiteSpace(request.OrderId) ? null : request.OrderId.Trim(),
                Subject = request.Subject.Trim(),
                Description = request.Description.Trim(),
                Priority = string.IsNullOrWhiteSpace(request.Priority) ? "Normal" : request.Priority.Trim(),
                Status = "Open",
                CreatedAtUtc = DateTime.UtcNow,
                UpdatedAtUtc = DateTime.UtcNow,
            };

            _context.SupportCases.Add(entity);
            await _context.SaveChangesAsync();
            await WriteAuditAsync("support.case.created", userId, "Info", $"{{\"caseId\":{entity.Id}}}");

            return CreatedAtAction(nameof(GetSupportCases), new { id = entity.Id }, entity);
        }

        /// <summary>
        /// Assigns a support case to a support agent.
        /// </summary>
        [HttpPut("{id:int}/assign")]
        [Authorize(Roles = "Admin,Manager,Support,QaTester")]
        [ProducesResponseType(typeof(SupportCase), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<ActionResult<SupportCase>> AssignSupportCase(int id, [FromBody] AssignSupportCaseRequest request)
        {
            var entity = await _context.SupportCases.FirstOrDefaultAsync(c => c.Id == id);
            if (entity == null)
            {
                return NotFound(new { Message = "Support case not found." });
            }

            if (string.IsNullOrWhiteSpace(request.AssignedToUserId))
            {
                return BadRequest(new { Message = "AssignedToUserId is required." });
            }

            var assignmentConflictDefect = await _context.QaFeatureFlags
                .Where(f => f.Key == "support_assignment_conflict")
                .Select(f => f.IsEnabled)
                .FirstOrDefaultAsync();

            if (assignmentConflictDefect && !string.IsNullOrWhiteSpace(entity.AssignedToUserId))
            {
                entity.AssignedToUserId = "user-4";
            }
            else
            {
                entity.AssignedToUserId = request.AssignedToUserId.Trim();
            }

            entity.Status = entity.Status == "Open" ? "InProgress" : entity.Status;
            entity.UpdatedAtUtc = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            await WriteAuditAsync("support.case.assigned", User.FindFirstValue(ClaimTypes.NameIdentifier), "Info", $"{{\"caseId\":{entity.Id},\"assignee\":\"{entity.AssignedToUserId}\"}}");

            return Ok(entity);
        }

        /// <summary>
        /// Updates support case status.
        /// </summary>
        [HttpPut("{id:int}/status")]
        [Authorize(Roles = "Admin,Manager,Support,QaTester")]
        [ProducesResponseType(typeof(SupportCase), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<ActionResult<SupportCase>> UpdateSupportCaseStatus(int id, [FromBody] UpdateSupportCaseStatusRequest request)
        {
            var entity = await _context.SupportCases.FirstOrDefaultAsync(c => c.Id == id);
            if (entity == null)
            {
                return NotFound(new { Message = "Support case not found." });
            }

            if (string.IsNullOrWhiteSpace(request.Status))
            {
                return BadRequest(new { Message = "Status is required." });
            }

            entity.Status = request.Status.Trim();
            entity.UpdatedAtUtc = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            await WriteAuditAsync("support.case.status.updated", User.FindFirstValue(ClaimTypes.NameIdentifier), "Info", $"{{\"caseId\":{entity.Id},\"status\":\"{entity.Status}\"}}");

            return Ok(entity);
        }

        private async Task WriteAuditAsync(string eventType, string? userId, string severity, string details)
        {
            var verboseAudit = await _context.QaFeatureFlags
                .Where(f => f.Key == "audit_verbose_events")
                .Select(f => f.IsEnabled)
                .FirstOrDefaultAsync();
            if (!verboseAudit)
            {
                return;
            }

            _context.AuditLogs.Add(new AuditLog
            {
                TimestampUtc = DateTime.UtcNow,
                EventType = eventType,
                UserId = userId,
                Severity = severity,
                Details = details
            });
            await _context.SaveChangesAsync();
        }
    }
}
