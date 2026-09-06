using System;
using System.Collections.Generic;

namespace LewisStores.Api.Models
{
    /// <summary>
    /// Product entity shown in catalog and product listing views.
    /// </summary>
    public class Product
    {
        /// <summary>
        /// Unique product identifier.
        /// </summary>
        public string Id { get; set; } = string.Empty;

        /// <summary>
        /// Display title for the product.
        /// </summary>
        public string Title { get; set; } = string.Empty;

        /// <summary>
        /// Product description text.
        /// </summary>
        public string Description { get; set; } = string.Empty;

        /// <summary>
        /// Current selling price.
        /// </summary>
        public decimal Price { get; set; }

        /// <summary>
        /// Previous price used for promotions, when available.
        /// </summary>
        public decimal? OldPrice { get; set; }

        /// <summary>
        /// Optional promotional label, such as New or Sale.
        /// </summary>
        public string? Tag { get; set; }

        /// <summary>
        /// Average customer rating.
        /// </summary>
        public double Rating { get; set; }

        /// <summary>
        /// Product category used for filtering and merchandising.
        /// </summary>
        public string Category { get; set; } = string.Empty;

        /// <summary>
        /// Foreign key to the normalized category row.
        /// </summary>
        public string CategoryId { get; set; } = string.Empty;

        /// <summary>
        /// Navigation to the normalized category entity.
        /// </summary>
        public Category? CategoryEntity { get; set; }

        /// <summary>
        /// Public product image URL.
        /// </summary>
        public string Image { get; set; } = string.Empty;

        /// <summary>
        /// Internal stock keeping unit code.
        /// </summary>
        public string Sku { get; set; } = string.Empty;

        /// <summary>
        /// Current available inventory quantity.
        /// </summary>
        public int StockQuantity { get; set; }

        /// <summary>
        /// Indicates whether the product is currently active in the catalog.
        /// </summary>
        public bool IsActive { get; set; } = true;
    }

    /// <summary>
    /// Category used to organize product catalog sections.
    /// </summary>
    public class Category
    {
        /// <summary>
        /// Unique category identifier.
        /// </summary>
        public string Id { get; set; } = Guid.NewGuid().ToString();

        /// <summary>
        /// Category display name.
        /// </summary>
        public string Name { get; set; } = string.Empty;

        /// <summary>
        /// Category description text.
        /// </summary>
        public string Description { get; set; } = string.Empty;

        /// <summary>
        /// UI route destination associated with the category.
        /// </summary>
        public string To { get; set; } = string.Empty;

        /// <summary>
        /// Visual tone identifier used by the frontend.
        /// </summary>
        public string Tone { get; set; } = string.Empty;

        /// <summary>
        /// Products assigned to this category.
        /// </summary>
        public List<Product> Products { get; set; } = new List<Product>();
    }

    /// <summary>
    /// Cart line item representing a selected product and quantity.
    /// </summary>
    public class CartItem
    {
        /// <summary>
        /// Internal database key for the cart item.
        /// </summary>
        public int InternalId { get; set; } // DB PK

        /// <summary>
        /// Product identifier.
        /// </summary>
        public string Id { get; set; } = string.Empty; // Product ID

        /// <summary>
        /// Product title at the time it was added to cart.
        /// </summary>
        public string Title { get; set; } = string.Empty;

        /// <summary>
        /// Selected product variant.
        /// </summary>
        public string Variant { get; set; } = string.Empty;

        /// <summary>
        /// Number of units in the cart.
        /// </summary>
        public int Quantity { get; set; }

        /// <summary>
        /// Unit price at time of cart update.
        /// </summary>
        public decimal Price { get; set; }
    }

    /// <summary>
    /// Customer order summary model.
    /// </summary>
    public class Order
    {
        /// <summary>
        /// Order identifier.
        /// </summary>
        public string Id { get; set; } = string.Empty;

        /// <summary>
        /// Human-readable order date.
        /// </summary>
        public string Date { get; set; } = string.Empty;

        /// <summary>
        /// Current order status.
        /// </summary>
        public string Status { get; set; } = string.Empty;

        /// <summary>
        /// Final order total amount.
        /// </summary>
        public decimal Total { get; set; }

        /// <summary>
        /// Associated user identifier.
        /// </summary>
        public string? UserId { get; set; }

        /// <summary>
        /// Human-readable order item summary.
        /// </summary>
        public string Items { get; set; } = string.Empty;
        /// <summary>
        /// Normalized order line items (preferred for DB joins and validation).
        /// </summary>
        public List<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
    }

    /// <summary>
    /// Normalized order line item linking orders to products and quantities.
    /// </summary>
    public class OrderItem
    {
        /// <summary>
        /// Numeric primary key for the line item.
        /// </summary>
        public int Id { get; set; }

        /// <summary>
        /// Associated order identifier.
        /// </summary>
        public string OrderId { get; set; } = string.Empty;

        /// <summary>
        /// Product identifier for the line.
        /// </summary>
        public string ProductId { get; set; } = string.Empty;

        /// <summary>
        /// Number of units ordered.
        /// </summary>
        public int Quantity { get; set; }

        /// <summary>
        /// Unit price at time of order (in cents/units matching Product.Price scale).
        /// </summary>
        public decimal UnitPrice { get; set; }

        /// <summary>
        /// Line total = Quantity * UnitPrice.
        /// </summary>
        public decimal LineTotal { get; set; }

        /// <summary>
        /// Navigation property to Order (optional for seeding and queries).
        /// </summary>
        public Order? Order { get; set; }

        /// <summary>
        /// Navigation property to Product (optional for queries).
        /// </summary>
        public Product? Product { get; set; }
    }

    /// <summary>
    /// Delivery and shipping status tied to a customer order.
    /// </summary>
    public class Delivery
    {
        /// <summary>
        /// Numeric primary key.
        /// </summary>
        public int Id { get; set; }

        /// <summary>
        /// Associated order identifier.
        /// </summary>
        public string OrderId { get; set; } = string.Empty;

        /// <summary>
        /// Customer/user identifier.
        /// </summary>
        public string UserId { get; set; } = string.Empty;

        /// <summary>
        /// Current delivery status.
        /// </summary>
        public string Status { get; set; } = string.Empty;

        /// <summary>
        /// Carrier responsible for the shipment.
        /// </summary>
        public string Carrier { get; set; } = string.Empty;

        /// <summary>
        /// Tracking number exposed to the customer.
        /// </summary>
        public string TrackingNumber { get; set; } = string.Empty;

        /// <summary>
        /// Dispatch hub or origin location.
        /// </summary>
        public string Origin { get; set; } = string.Empty;

        /// <summary>
        /// Delivery destination address or region.
        /// </summary>
        public string Destination { get; set; } = string.Empty;

        /// <summary>
        /// Latest known delivery location.
        /// </summary>
        public string CurrentLocation { get; set; } = string.Empty;

        /// <summary>
        /// UTC timestamp when the order left the warehouse, if applicable.
        /// </summary>
        public DateTime? ShippedAtUtc { get; set; }

        /// <summary>
        /// Estimated delivery date and time in UTC.
        /// </summary>
        public DateTime EstimatedDeliveryAtUtc { get; set; }

        /// <summary>
        /// UTC timestamp when the shipment was completed, if applicable.
        /// </summary>
        public DateTime? DeliveredAtUtc { get; set; }

        /// <summary>
        /// UTC timestamp for the most recent status update.
        /// </summary>
        public DateTime UpdatedAtUtc { get; set; }
    }

    /// <summary>
    /// Application user model used for mock authentication.
    /// </summary>
    public class User
    {
        /// <summary>
        /// User identifier.
        /// </summary>
        public string Id { get; set; } = Guid.NewGuid().ToString();

        /// <summary>
        /// User email address.
        /// </summary>
        public string Email { get; set; } = string.Empty;

        /// <summary>
        /// User password for mock login only.
        /// </summary>
        public string Password { get; set; } = string.Empty; // Mock, not hashed

        /// <summary>
        /// User role used in authorization claims.
        /// </summary>
        public string Role { get; set; } = "Customer";

        /// <summary>
        /// User display name.
        /// </summary>
        public string FullName { get; set; } = string.Empty;

        /// <summary>
        /// User contact phone.
        /// </summary>
        public string Phone { get; set; } = string.Empty;

        /// <summary>
        /// User primary address.
        /// </summary>
        public string Address { get; set; } = string.Empty;
    }

    /// <summary>
    /// Stored payment method linked to a user account.
    /// </summary>
    public class PaymentMethod
    {
        /// <summary>
        /// Numeric primary key.
        /// </summary>
        public int Id { get; set; }

        /// <summary>
        /// Associated user identifier.
        /// </summary>
        public string UserId { get; set; } = string.Empty;

        /// <summary>
        /// Cardholder full name.
        /// </summary>
        public string CardholderName { get; set; } = string.Empty;

        /// <summary>
        /// Last four card digits.
        /// </summary>
        public string Last4 { get; set; } = string.Empty;

        /// <summary>
        /// Payment brand label.
        /// </summary>
        public string Brand { get; set; } = "Card";

        /// <summary>
        /// Expiry month and year in MM/YY format.
        /// </summary>
        public string Expiry { get; set; } = string.Empty;

        /// <summary>
        /// True when this is the default payment method.
        /// </summary>
        public bool IsDefault { get; set; }
    }

    /// <summary>
    /// Credit application submitted by a user.
    /// </summary>
    public class CreditApplication
    {
        /// <summary>
        /// Numeric database identifier.
        /// </summary>
        public int Id { get; set; }

        /// <summary>
        /// Associated user identifier.
        /// </summary>
        public string UserId { get; set; } = string.Empty;

        /// <summary>
        /// Current credit application status.
        /// </summary>
        public string Status { get; set; } = "Pending";

        /// <summary>
        /// UTC timestamp when the application was submitted.
        /// </summary>
        public DateTime ApplicationDate { get; set; } = DateTime.UtcNow;

        /// <summary>
        /// National ID number supplied by the applicant.
        /// </summary>
        public string IdNumber { get; set; } = string.Empty;

        /// <summary>
        /// Applicant employment status.
        /// </summary>
        public string EmploymentStatus { get; set; } = string.Empty;

        /// <summary>
        /// Applicant's monthly income amount.
        /// </summary>
        public decimal MonthlyIncome { get; set; }

        /// <summary>
        /// Applicant's monthly expenses amount.
        /// </summary>
        public decimal MonthlyExpenses { get; set; }
    }

    /// <summary>
    /// Return and refund request raised against an order.
    /// </summary>
    public class ReturnRequest
    {
        /// <summary>
        /// Numeric primary key.
        /// </summary>
        public int Id { get; set; }

        /// <summary>
        /// Associated order identifier.
        /// </summary>
        public string OrderId { get; set; } = string.Empty;

        /// <summary>
        /// Customer/user identifier who submitted the request.
        /// </summary>
        public string UserId { get; set; } = string.Empty;

        /// <summary>
        /// Return reason provided by the customer.
        /// </summary>
        public string Reason { get; set; } = string.Empty;

        /// <summary>
        /// Current return workflow status.
        /// </summary>
        public string Status { get; set; } = "PendingReview";

        /// <summary>
        /// Requested refund amount.
        /// </summary>
        public decimal RequestedAmount { get; set; }

        /// <summary>
        /// Approved refund amount once processed.
        /// </summary>
        public decimal? ApprovedAmount { get; set; }

        /// <summary>
        /// Resolution notes recorded by support.
        /// </summary>
        public string ResolutionNotes { get; set; } = string.Empty;

        /// <summary>
        /// UTC timestamp when request was submitted.
        /// </summary>
        public DateTime RequestedAtUtc { get; set; } = DateTime.UtcNow;

        /// <summary>
        /// UTC timestamp when request was last updated.
        /// </summary>
        public DateTime UpdatedAtUtc { get; set; } = DateTime.UtcNow;
    }

    /// <summary>
    /// Customer support case linked to account and order activity.
    /// </summary>
    public class SupportCase
    {
        /// <summary>
        /// Numeric primary key.
        /// </summary>
        public int Id { get; set; }

        /// <summary>
        /// Optional related order identifier.
        /// </summary>
        public string? OrderId { get; set; }

        /// <summary>
        /// Requesting customer/user identifier.
        /// </summary>
        public string UserId { get; set; } = string.Empty;

        /// <summary>
        /// Support issue subject line.
        /// </summary>
        public string Subject { get; set; } = string.Empty;

        /// <summary>
        /// Detailed support request description.
        /// </summary>
        public string Description { get; set; } = string.Empty;

        /// <summary>
        /// Current case workflow status.
        /// </summary>
        public string Status { get; set; } = "Open";

        /// <summary>
        /// Priority marker used by support teams.
        /// </summary>
        public string Priority { get; set; } = "Normal";

        /// <summary>
        /// User identifier of assigned support agent.
        /// </summary>
        public string? AssignedToUserId { get; set; }

        /// <summary>
        /// UTC timestamp when the case was created.
        /// </summary>
        public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

        /// <summary>
        /// UTC timestamp when the case was last updated.
        /// </summary>
        public DateTime UpdatedAtUtc { get; set; } = DateTime.UtcNow;
    }

    /// <summary>
    /// Student-submitted defect report captured during training missions.
    /// </summary>
    public class DefectReport
    {
        /// <summary>
        /// Numeric primary key.
        /// </summary>
        public int Id { get; set; }

        /// <summary>
        /// Mission identifier associated with this defect report.
        /// </summary>
        public string MissionKey { get; set; } = string.Empty;

        /// <summary>
        /// Short defect summary.
        /// </summary>
        public string Title { get; set; } = string.Empty;

        /// <summary>
        /// Severity classification provided by the student.
        /// </summary>
        public string Severity { get; set; } = "Medium";

        /// <summary>
        /// Reproduction instructions.
        /// </summary>
        public string StepsToReproduce { get; set; } = string.Empty;

        /// <summary>
        /// Expected behavior summary.
        /// </summary>
        public string ExpectedResult { get; set; } = string.Empty;

        /// <summary>
        /// Actual observed behavior.
        /// </summary>
        public string ActualResult { get; set; } = string.Empty;

        /// <summary>
        /// Optional contextual notes such as browser, role, and scenario pack.
        /// </summary>
        public string EnvironmentNotes { get; set; } = string.Empty;

        /// <summary>
        /// Review workflow state.
        /// </summary>
        public string Status { get; set; } = "Submitted";

        /// <summary>
        /// Student user identifier.
        /// </summary>
        public string SubmittedByUserId { get; set; } = string.Empty;

        /// <summary>
        /// UTC timestamp when report was submitted.
        /// </summary>
        public DateTime SubmittedAtUtc { get; set; } = DateTime.UtcNow;

        /// <summary>
        /// Instructor feedback captured during review.
        /// </summary>
        public string InstructorFeedback { get; set; } = string.Empty;

        /// <summary>
        /// Optional instructor-assigned score.
        /// </summary>
        public int? Score { get; set; }
    }

    /// <summary>
    /// Mission progress and completion record for training analytics.
    /// </summary>
    public class MissionProgress
    {
        /// <summary>
        /// Numeric primary key.
        /// </summary>
        public int Id { get; set; }

        /// <summary>
        /// Mission key.
        /// </summary>
        public string MissionKey { get; set; } = string.Empty;

        /// <summary>
        /// User identifier for the trainee.
        /// </summary>
        public string UserId { get; set; } = string.Empty;

        /// <summary>
        /// Persona used by the trainee for this mission.
        /// </summary>
        public string PersonaKey { get; set; } = "customer";

        /// <summary>
        /// Mission status value.
        /// </summary>
        public string Status { get; set; } = "NotStarted";

        /// <summary>
        /// Numeric mission score out of 100.
        /// </summary>
        public int Score { get; set; }

        /// <summary>
        /// Badge tier awarded for this mission.
        /// </summary>
        public string Badge { get; set; } = "None";

        /// <summary>
        /// UTC timestamp for mission start.
        /// </summary>
        public DateTime StartedAtUtc { get; set; } = DateTime.UtcNow;

        /// <summary>
        /// UTC timestamp for mission completion.
        /// </summary>
        public DateTime? CompletedAtUtc { get; set; }
    }

    /// <summary>
    /// Feature flag used to enable controlled training scenarios.
    /// </summary>
    public class QaFeatureFlag
    {
        /// <summary>
        /// Unique feature flag identifier.
        /// </summary>
        public string Key { get; set; } = string.Empty;

        /// <summary>
        /// Human-readable description of the scenario.
        /// </summary>
        public string Description { get; set; } = string.Empty;

        /// <summary>
        /// True when the training scenario is active.
        /// </summary>
        public bool IsEnabled { get; set; }

        /// <summary>
        /// Last UTC update timestamp.
        /// </summary>
        public DateTime UpdatedAtUtc { get; set; } = DateTime.UtcNow;
    }

    /// <summary>
    /// Audit log entry for training investigations.
    /// </summary>
    public class AuditLog
    {
        /// <summary>
        /// Numeric primary key.
        /// </summary>
        public long Id { get; set; }

        /// <summary>
        /// UTC timestamp of the event.
        /// </summary>
        public DateTime TimestampUtc { get; set; } = DateTime.UtcNow;

        /// <summary>
        /// Event type key.
        /// </summary>
        public string EventType { get; set; } = string.Empty;

        /// <summary>
        /// User identifier responsible for the event when available.
        /// </summary>
        public string? UserId { get; set; }

        /// <summary>
        /// Severity level classification.
        /// </summary>
        public string Severity { get; set; } = "Info";

        /// <summary>
        /// Event details payload in plain text JSON-like format.
        /// </summary>
        public string Details { get; set; } = string.Empty;
    }
}
