using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LewisStores.Api.Data;
using LewisStores.Api.Models;

namespace LewisStores.Api.Controllers
{
    /// <summary>
    /// Exposes product category endpoints.
    /// </summary>
    [Route("api/[controller]")]
    [ApiController]
    public class CategoriesController : ControllerBase
    {
        private readonly AppDbContext _context;

        public CategoriesController(AppDbContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Returns all available product categories.
        /// </summary>
        [HttpGet]
        [ProducesResponseType(typeof(IEnumerable<Category>), StatusCodes.Status200OK)]
        public async Task<ActionResult<IEnumerable<Category>>> GetCategories()
        {
            return await _context.Categories.ToListAsync();
        }
    }
}
