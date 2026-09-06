using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LewisStores.Api.Data;
using LewisStores.Api.Models;

namespace LewisStores.Api.Controllers
{
    /// <summary>
    /// Exposes product catalog endpoints.
    /// </summary>
    [Route("api/[controller]")]
    [ApiController]
    public class ProductsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public class CreateProductRequest
        {
            public string Title { get; set; } = string.Empty;
            public string Description { get; set; } = string.Empty;
            public decimal Price { get; set; }
            public decimal? OldPrice { get; set; }
            public string? Tag { get; set; }
            public double? Rating { get; set; }
            public string Category { get; set; } = string.Empty;
            public string Image { get; set; } = string.Empty;
            public int StockQuantity { get; set; }
        }

        public class UpdateProductStockRequest
        {
            public int StockQuantity { get; set; }
        }

        public ProductsController(AppDbContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Returns the full list of products.
        /// </summary>
        [HttpGet]
        [ProducesResponseType(typeof(IEnumerable<Product>), StatusCodes.Status200OK)]
        public async Task<ActionResult<IEnumerable<Product>>> GetProducts()
        {
            var products = await _context.Products.ToListAsync();

            var duplicateDefectEnabled = await _context.QaFeatureFlags
                .Where(f => f.Key == "product_duplicate_in_list")
                .Select(f => f.IsEnabled)
                .FirstOrDefaultAsync();

            if (duplicateDefectEnabled && products.Count > 0)
            {
                products.Add(products[0]);
            }

            return products;
        }

        /// <summary>
        /// Creates a new product and stores its initial stock quantity.
        /// </summary>
        [HttpPost]
        [ProducesResponseType(typeof(Product), StatusCodes.Status201Created)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<ActionResult<Product>> CreateProduct([FromBody] CreateProductRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Title) ||
                string.IsNullOrWhiteSpace(request.Description) ||
                string.IsNullOrWhiteSpace(request.Category) ||
                string.IsNullOrWhiteSpace(request.Image))
            {
                return BadRequest(new { Message = "Title, description, category, and image are required." });
            }

            if (request.Price <= 0)
            {
                return BadRequest(new { Message = "Price must be greater than zero." });
            }

            if (request.StockQuantity < 0)
            {
                return BadRequest(new { Message = "StockQuantity cannot be negative." });
            }

            var categoryName = request.Category.Trim();
            var category = await _context.Categories
                .FirstOrDefaultAsync(c => c.Name == categoryName);

            if (category == null)
            {
                return BadRequest(new
                {
                    Message = $"Category '{categoryName}' does not exist.",
                    AllowedCategories = await _context.Categories.Select(c => c.Name).OrderBy(name => name).ToListAsync()
                });
            }

            var categoryCode = new string(request.Category
                .Trim()
                .Where(char.IsLetterOrDigit)
                .Take(3)
                .ToArray())
                .ToUpperInvariant();

            if (string.IsNullOrWhiteSpace(categoryCode))
            {
                categoryCode = "PRD";
            }

            string sku;
            do
            {
                sku = $"LEW-{categoryCode}-{Random.Shared.Next(1000, 9999)}";
            }
            while (await _context.Products.AnyAsync(p => p.Sku == sku));

            var product = new Product
            {
                Id = $"prod-{Guid.NewGuid():N}",
                Title = request.Title.Trim(),
                Description = request.Description.Trim(),
                Price = request.Price,
                OldPrice = request.OldPrice,
                Tag = string.IsNullOrWhiteSpace(request.Tag) ? null : request.Tag.Trim(),
                Rating = request.Rating ?? 0,
                Category = category.Name,
                CategoryId = category.Id,
                Image = request.Image.Trim(),
                Sku = sku,
                StockQuantity = request.StockQuantity,
                IsActive = true
            };

            _context.Products.Add(product);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetProduct), new { id = product.Id }, product);
        }

        /// <summary>
        /// Updates the stock quantity for an existing product.
        /// </summary>
        [HttpPatch("{id}/stock")]
        [ProducesResponseType(typeof(Product), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<ActionResult<Product>> UpdateProductStock(string id, [FromBody] UpdateProductStockRequest request)
        {
            if (request.StockQuantity < 0)
            {
                return BadRequest(new { Message = "StockQuantity cannot be negative." });
            }

            var product = await _context.Products.FirstOrDefaultAsync(p => p.Id == id);
            if (product == null)
            {
                return NotFound(new { Message = "Product not found." });
            }

            product.StockQuantity = request.StockQuantity;
            await _context.SaveChangesAsync();

            return Ok(product);
        }

        /// <summary>
        /// Returns a single product by identifier.
        /// </summary>
        /// <param name="id">Product identifier.</param>
        [HttpGet("{id}")]
        [ProducesResponseType(typeof(Product), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<ActionResult<Product>> GetProduct(string id)
        {
            var product = await _context.Products.FindAsync(id);
            if (product == null) return NotFound();
            return product;
        }

        /// <summary>
        /// Returns a product by SKU and maps unknown SKUs to a not-found state.
        /// </summary>
        [HttpGet("sku/{sku}")]
        [ProducesResponseType(typeof(Product), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<ActionResult<Product>> GetProductBySku(string sku)
        {
            var product = await _context.Products.FirstOrDefaultAsync(p => p.Sku == sku);
            if (product == null)
            {
                return NotFound(new
                {
                    Message = $"Product with SKU '{sku}' was not found.",
                    Sku = sku,
                    Status = "NotFound"
                });
            }

            return product;
        }
    }
}
