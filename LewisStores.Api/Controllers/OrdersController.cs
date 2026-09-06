using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using LewisStores.Api.Data;
using LewisStores.Api.Models;

namespace LewisStores.Api.Controllers
{
    /// <summary>
    /// Handles order retrieval and creation endpoints.
    /// </summary>
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class OrdersController : ControllerBase
    {
        private readonly AppDbContext _context;

        public class CreateOrderRequest
        {
            public decimal Total { get; set; }
            public string Items { get; set; } = string.Empty;
            public List<CreateOrderItem>? ItemsList { get; set; }
        }

        public class CreateOrderItem
        {
            public string ProductId { get; set; } = string.Empty;
            public int Quantity { get; set; }
            public decimal UnitPrice { get; set; }
        }

        public OrdersController(AppDbContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Returns all orders.
        /// </summary>
        [HttpGet]
        [ProducesResponseType(typeof(IEnumerable<Order>), StatusCodes.Status200OK)]
        public async Task<ActionResult<IEnumerable<Order>>> GetOrders()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            var orders = await _context.Orders
                .Where(o => o.UserId == userId)
                .Include(o => o.OrderItems)
                .ThenInclude(oi => oi.Product)
                .OrderByDescending(o => o.Date)
                .ToListAsync();

            var mismatchDefectEnabled = await _context.QaFeatureFlags
                .Where(f => f.Key == "order_total_mismatch")
                .Select(f => f.IsEnabled)
                .FirstOrDefaultAsync();

            if (mismatchDefectEnabled && orders.Count > 0)
            {
                orders[0].Total += 1.11m;
            }

            return orders;
        }

        /// <summary>
        /// Creates a new order and returns the created resource.
        /// </summary>
        /// <param name="request">Order payload.</param>
        [HttpPost]
        [ProducesResponseType(typeof(Order), StatusCodes.Status201Created)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<ActionResult<Order>> CreateOrder([FromBody] CreateOrderRequest request)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            if (request.Total <= 0)
            {
                return BadRequest(new { Message = "Order total must be greater than zero." });
            }

            if (request.ItemsList == null || request.ItemsList.Count == 0)
            {
                return BadRequest(new { Message = "Structured order items are required." });
            }

            var productIds = request.ItemsList
                .Select(item => item.ProductId)
                .Where(productId => !string.IsNullOrWhiteSpace(productId))
                .Distinct()
                .ToList();

            if (productIds.Count == 0)
            {
                return BadRequest(new { Message = "At least one product is required." });
            }

            var products = await _context.Products
                .Where(product => productIds.Contains(product.Id))
                .ToListAsync();

            if (products.Count != productIds.Count)
            {
                var missingProductIds = productIds.Except(products.Select(product => product.Id)).ToList();
                return BadRequest(new
                {
                    Message = "One or more products referenced in the order do not exist.",
                    MissingProductIds = missingProductIds
                });
            }

            var productsById = products.ToDictionary(product => product.Id, product => product);

            var order = new Order
            {
                Id = "LWS-" + Random.Shared.Next(10000, 99999),
                Date = DateTime.UtcNow.ToString("dd MMM yyyy"),
                Status = "Processing",
                UserId = userId,
                Items = string.Join(" + ", request.ItemsList.Select(item => productsById[item.ProductId].Title))
            };

            var createdOrderItems = new List<OrderItem>();
            foreach (var it in request.ItemsList)
            {
                if (it.Quantity <= 0)
                {
                    return BadRequest(new { Message = "Order item quantity must be greater than zero." });
                }

                if (it.UnitPrice <= 0)
                {
                    return BadRequest(new { Message = "Order item unit price must be greater than zero." });
                }

                var product = productsById[it.ProductId];
                var lineTotal = it.UnitPrice * it.Quantity;
                createdOrderItems.Add(new OrderItem
                {
                    ProductId = product.Id,
                    Quantity = it.Quantity,
                    UnitPrice = it.UnitPrice,
                    LineTotal = lineTotal,
                    OrderId = order.Id,
                    Product = product
                });
            }

            order.Total = createdOrderItems.Sum(x => x.LineTotal);
            order.OrderItems = createdOrderItems;

            _context.Orders.Add(order);
            _context.OrderItems.AddRange(createdOrderItems);

            await _context.SaveChangesAsync();

            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
            var now = DateTime.UtcNow;
            _context.Deliveries.Add(new Delivery
            {
                OrderId = order.Id,
                UserId = userId,
                Status = "Processing",
                Carrier = "Lewis Logistics",
                TrackingNumber = $"LL-{order.Id}",
                Origin = "Johannesburg Distribution Centre",
                Destination = user?.Address?.Trim() ?? string.Empty,
                CurrentLocation = "Order received at the dispatch hub",
                ShippedAtUtc = null,
                EstimatedDeliveryAtUtc = now.AddDays(5),
                DeliveredAtUtc = null,
                UpdatedAtUtc = now
            });
            await _context.SaveChangesAsync();

            var verboseAudit = await _context.QaFeatureFlags
                .Where(f => f.Key == "audit_verbose_events")
                .Select(f => f.IsEnabled)
                .FirstOrDefaultAsync();

            if (verboseAudit)
            {
                _context.AuditLogs.Add(new AuditLog
                {
                    TimestampUtc = DateTime.UtcNow,
                    EventType = "order.created",
                    UserId = userId,
                    Severity = "Info",
                    Details = $"{{\"orderId\":\"{order.Id}\",\"total\":{order.Total}}}"
                });
                await _context.SaveChangesAsync();
            }

            var createdOrder = await _context.Orders
                .Where(o => o.Id == order.Id)
                .Include(o => o.OrderItems)
                .ThenInclude(oi => oi.Product)
                .FirstAsync();

            return CreatedAtAction(nameof(GetOrders), new { id = order.Id }, createdOrder);
        }
    }
}
