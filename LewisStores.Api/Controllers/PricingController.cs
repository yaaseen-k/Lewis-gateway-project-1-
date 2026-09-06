using Microsoft.AspNetCore.Mvc;
using LewisStores.Api.Data;

namespace LewisStores.Api.Controllers
{
    /// <summary>
    /// Validates pricing, VAT, and revenue integrity rules for retail transactions.
    /// </summary>
    [Route("api/[controller]")]
    [ApiController]
    public class PricingController : ControllerBase
    {
        private readonly AppDbContext _context;

        public PricingController(AppDbContext context)
        {
            _context = context;
        }

        public class ValidatePricingRequest
        {
            public decimal UnitPrice { get; set; }
            public int Quantity { get; set; }
            public decimal VatRate { get; set; } = 0.15m;
            public bool AllowZeroValue { get; set; }
        }

        /// <summary>
        /// Validates the pricing calculation for an order line and returns VAT details.
        /// </summary>
        [HttpPost("validate")]
        [ProducesResponseType(typeof(object), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<ActionResult<object>> ValidatePricing([FromBody] ValidatePricingRequest request)
        {
            if (request.Quantity <= 0)
            {
                return BadRequest(new { Message = "Quantity must be greater than zero." });
            }

            var subtotal = request.UnitPrice * request.Quantity;
            var vatAmount = subtotal * request.VatRate;
            var total = subtotal + vatAmount;

            if (!request.AllowZeroValue && total <= 0)
            {
                return BadRequest(new
                {
                    Message = "Transaction total resolves to R0.00 and cannot be finalized unless explicitly allowed.",
                    Total = 0m,
                    VatAmount = 0m
                });
            }

            if (request.UnitPrice < 0)
            {
                return BadRequest(new { Message = "Unit price cannot be negative." });
            }

            var auditPayload = new
            {
                subtotal,
                vatRate = request.VatRate,
                vatAmount,
                total,
                currency = "ZAR"
            };

            await Task.CompletedTask;
            return Ok(auditPayload);
        }
    }
}
