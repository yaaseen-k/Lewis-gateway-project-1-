using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using LewisStores.Api.Data;
using LewisStores.Api.Models;

namespace LewisStores.Api.Controllers
{
    /// <summary>
    /// Handles return and refund workflows for customer orders.
    /// </summary>
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class ReturnsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public ReturnsController(AppDbContext context)
        {
            _context = context;
        }

        public class CreateReturnRequest
        {
            public string OrderId { get; set; } = string.Empty;
            public string Reason { get; set; } = string.Empty;
            public decimal RequestedAmount { get; set; }
        }

        public class UpdateReturnStatusRequest
        {
            public string Status { get; set; } = string.Empty;
            public decimal? ApprovedAmount { get; set; }
            public string ResolutionNotes { get; set; } = string.Empty;
        }

        /// <summary>
        /// Returns return requests. Support/admin roles can view all; customers view their own.
        /// </summary>
        [HttpGet]
        [ProducesResponseType(typeof(IEnumerable<ReturnRequest>), StatusCodes.Status200OK)]
        public async Task<ActionResult<IEnumerable<ReturnRequest>>> GetReturns()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            var isStaff = User.IsInRole("Admin") || User.IsInRole("Manager") || User.IsInRole("Support") || User.IsInRole("QaTester");
            var query = _context.ReturnRequests.AsQueryable();
            if (!isStaff)
            {
                query = query.Where(r => r.UserId == userId);
            }

            var data = await query
                .OrderByDescending(r => r.UpdatedAtUtc)
                .ToListAsync();

            return data;
        }

        /// <summary>
        /// Creates a new return request for the authenticated customer.
        /// </summary>
        [HttpPost]
        [ProducesResponseType(typeof(ReturnRequest), StatusCodes.Status201Created)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<ActionResult<ReturnRequest>> CreateReturn([FromBody] CreateReturnRequest request)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            if (string.IsNullOrWhiteSpace(request.OrderId) || string.IsNullOrWhiteSpace(request.Reason) || request.RequestedAmount <= 0)
            {
                return BadRequest(new { Message = "OrderId, reason, and requestedAmount are required." });
            }

            var order = await _context.Orders.FirstOrDefaultAsync(o => o.Id == request.OrderId && o.UserId == userId);
            if (order == null)
            {
                return BadRequest(new { Message = "Order not found for current user." });
            }

            var entity = new ReturnRequest
            {
                OrderId = request.OrderId,
                UserId = userId,
                Reason = request.Reason.Trim(),
                RequestedAmount = request.RequestedAmount,
                Status = "PendingReview",
                RequestedAtUtc = DateTime.UtcNow,
                UpdatedAtUtc = DateTime.UtcNow,
            };

            _context.ReturnRequests.Add(entity);
            await _context.SaveChangesAsync();
            await WriteAuditAsync("returns.requested", userId, "Info", $"{{\"returnId\":{entity.Id},\"orderId\":\"{entity.OrderId}\"}}");

            return CreatedAtAction(nameof(GetReturns), new { id = entity.Id }, entity);
        }

        /// <summary>
        /// Updates a return request status and refund details.
        /// </summary>
        [HttpPut("{id:int}/status")]
        [Authorize(Roles = "Admin,Manager,Support,QaTester")]
        [ProducesResponseType(typeof(ReturnRequest), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<ActionResult<ReturnRequest>> UpdateReturnStatus(int id, [FromBody] UpdateReturnStatusRequest request)
        {
            var entity = await _context.ReturnRequests.FirstOrDefaultAsync(r => r.Id == id);
            if (entity == null)
            {
                return NotFound(new { Message = "Return request not found." });
            }

            if (!string.IsNullOrWhiteSpace(request.Status))
            {
                entity.Status = request.Status.Trim();
            }
            entity.ApprovedAmount = request.ApprovedAmount;
            entity.ResolutionNotes = request.ResolutionNotes?.Trim() ?? string.Empty;
            entity.UpdatedAtUtc = DateTime.UtcNow;

            var delayedPayoutDefect = await _context.QaFeatureFlags
                .Where(f => f.Key == "returns_refund_delay")
                .Select(f => f.IsEnabled)
                .FirstOrDefaultAsync();

            if (delayedPayoutDefect && entity.Status == "Approved")
            {
                entity.Status = "ApprovedPendingPayout";
            }

            await _context.SaveChangesAsync();
            await WriteAuditAsync("returns.status.updated", User.FindFirstValue(ClaimTypes.NameIdentifier), "Info", $"{{\"returnId\":{entity.Id},\"status\":\"{entity.Status}\"}}");

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
