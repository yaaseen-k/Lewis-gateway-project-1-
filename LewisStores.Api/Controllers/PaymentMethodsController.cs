using LewisStores.Api.Data;
using LewisStores.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace LewisStores.Api.Controllers
{
    /// <summary>
    /// Manages saved payment methods for authenticated users.
    /// </summary>
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class PaymentMethodsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public PaymentMethodsController(AppDbContext context)
        {
            _context = context;
        }

        public class SavePaymentMethodRequest
        {
            public string CardholderName { get; set; } = string.Empty;
            public string CardNumber { get; set; } = string.Empty;
            public string Brand { get; set; } = "Card";
            public string Expiry { get; set; } = string.Empty;
            public bool IsDefault { get; set; }
        }

        [HttpGet]
        [ProducesResponseType(typeof(IEnumerable<PaymentMethod>), StatusCodes.Status200OK)]
        public async Task<ActionResult<IEnumerable<PaymentMethod>>> GetPaymentMethods()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            var methods = await _context.PaymentMethods
                .Where(p => p.UserId == userId)
                .OrderByDescending(p => p.IsDefault)
                .ThenByDescending(p => p.Id)
                .ToListAsync();

            return methods;
        }

        [HttpPost]
        [ProducesResponseType(typeof(PaymentMethod), StatusCodes.Status201Created)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<ActionResult<PaymentMethod>> AddPaymentMethod([FromBody] SavePaymentMethodRequest request)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            var digits = new string((request.CardNumber ?? string.Empty).Where(char.IsDigit).ToArray());
            if (digits.Length < 12)
            {
                return BadRequest(new { Message = "Invalid card number." });
            }

            var paymentMethod = new PaymentMethod
            {
                UserId = userId,
                CardholderName = request.CardholderName.Trim(),
                Last4 = digits[^4..],
                Brand = string.IsNullOrWhiteSpace(request.Brand) ? "Card" : request.Brand.Trim(),
                Expiry = request.Expiry.Trim(),
                IsDefault = request.IsDefault
            };

            if (paymentMethod.IsDefault)
            {
                var existing = await _context.PaymentMethods.Where(p => p.UserId == userId).ToListAsync();
                foreach (var item in existing)
                {
                    item.IsDefault = false;
                }
            }

            _context.PaymentMethods.Add(paymentMethod);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetPaymentMethods), new { id = paymentMethod.Id }, paymentMethod);
        }

        [HttpDelete("{id:int}")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<IActionResult> DeletePaymentMethod(int id)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            var method = await _context.PaymentMethods.FirstOrDefaultAsync(p => p.Id == id && p.UserId == userId);
            if (method == null)
            {
                return NotFound();
            }

            _context.PaymentMethods.Remove(method);
            await _context.SaveChangesAsync();
            return NoContent();
        }
    }
}
