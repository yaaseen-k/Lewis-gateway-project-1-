using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LewisStores.Api.Data;
using LewisStores.Api.Models;

namespace LewisStores.Api.Controllers
{
    /// <summary>
    /// Manages shopping cart operations.
    /// </summary>
    [Route("api/[controller]")]
    [ApiController]
    public class CartController : ControllerBase
    {
        private readonly AppDbContext _context;

        public CartController(AppDbContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Returns all cart items for the current test cart.
        /// </summary>
        [HttpGet]
        [ProducesResponseType(typeof(IEnumerable<CartItem>), StatusCodes.Status200OK)]
        public async Task<ActionResult<IEnumerable<CartItem>>> GetCart()
        {
            return await _context.CartItems.ToListAsync();
        }

        /// <summary>
        /// Adds an item to the cart.
        /// </summary>
        /// <param name="item">Cart item to add.</param>
        [HttpPost]
        [ProducesResponseType(typeof(CartItem), StatusCodes.Status201Created)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<ActionResult<CartItem>> AddToCart([FromBody] CartItem item)
        {
            _context.CartItems.Add(item);
            await _context.SaveChangesAsync();
            return CreatedAtAction(nameof(GetCart), new { id = item.InternalId }, item);
        }

        /// <summary>
        /// Removes a cart item by internal database identifier.
        /// </summary>
        /// <param name="id">Internal cart item identifier.</param>
        [HttpDelete("{id}")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<IActionResult> RemoveFromCart(int id)
        {
            var item = await _context.CartItems.FindAsync(id);
            if (item == null) return NotFound();

            _context.CartItems.Remove(item);
            await _context.SaveChangesAsync();
            return NoContent();
        }
    }
}
