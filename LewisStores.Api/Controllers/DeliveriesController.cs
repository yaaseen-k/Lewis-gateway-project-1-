using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using LewisStores.Api.Data;
using LewisStores.Api.Models;

namespace LewisStores.Api.Controllers
{
    /// <summary>
    /// Exposes shipment and delivery tracking details for customer orders.
    /// </summary>
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class DeliveriesController : ControllerBase
    {
        private readonly AppDbContext _context;

        public DeliveriesController(AppDbContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Returns deliveries for the authenticated user, or all deliveries for staff roles.
        /// </summary>
        [HttpGet]
        [ProducesResponseType(typeof(IEnumerable<Delivery>), StatusCodes.Status200OK)]
        public async Task<ActionResult<IEnumerable<Delivery>>> GetDeliveries([FromQuery] string? status = null, [FromQuery] string? orderId = null)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            var isStaff = User.IsInRole("Admin") || User.IsInRole("Manager") || User.IsInRole("Support") || User.IsInRole("QaTester");
            var query = _context.Deliveries.AsQueryable();

            if (!isStaff)
            {
                query = query.Where(d => d.UserId == userId);
            }

            if (!string.IsNullOrWhiteSpace(orderId))
            {
                query = query.Where(d => d.OrderId == orderId.Trim());
            }

            if (!string.IsNullOrWhiteSpace(status))
            {
                query = query.Where(d => d.Status == status.Trim());
            }

            var deliveries = await query
                .OrderByDescending(d => d.UpdatedAtUtc)
                .ToListAsync();

            return Ok(deliveries);
        }

        /// <summary>
        /// Returns a single delivery record by order identifier.
        /// </summary>
        [HttpGet("{orderId}")]
        [ProducesResponseType(typeof(Delivery), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<ActionResult<Delivery>> GetDeliveryByOrderId(string orderId)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            var isStaff = User.IsInRole("Admin") || User.IsInRole("Manager") || User.IsInRole("Support") || User.IsInRole("QaTester");
            var delivery = await _context.Deliveries.FirstOrDefaultAsync(d => d.OrderId == orderId);

            if (delivery == null || (!isStaff && delivery.UserId != userId))
            {
                return NotFound(new { Message = "Delivery not found." });
            }

            return Ok(delivery);
        }
    }
}
