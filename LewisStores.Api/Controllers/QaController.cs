using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LewisStores.Api.Data;

namespace LewisStores.Api.Controllers
{
    /// <summary>
    /// QA training endpoints for inspecting scenario flags and audit events.
    /// </summary>
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class QaController : ControllerBase
    {
        private readonly AppDbContext _context;

        public QaController(AppDbContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Returns all QA feature flags with current state.
        /// </summary>
        [HttpGet("flags")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        public async Task<IActionResult> GetFlags()
        {
            var flags = await _context.QaFeatureFlags
                .OrderBy(f => f.Key)
                .Select(f => new
                {
                    f.Key,
                    f.Description,
                    f.IsEnabled,
                    f.UpdatedAtUtc
                })
                .ToListAsync();

            return Ok(flags);
        }

        /// <summary>
        /// Toggle a feature flag for QA scenario control.
        /// </summary>
        /// <param name="key">Feature flag key.</param>
        /// <param name="request">Toggle payload.</param>
        [HttpPut("flags/{key}")]
        [Authorize(Roles = "Admin,Manager,QaTester")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<IActionResult> UpdateFlag(string key, [FromBody] UpdateFlagRequest request)
        {
            var flag = await _context.QaFeatureFlags.FirstOrDefaultAsync(f => f.Key == key);
            if (flag == null)
            {
                return NotFound(new { Message = $"Feature flag '{key}' was not found." });
            }

            flag.IsEnabled = request.IsEnabled;
            flag.UpdatedAtUtc = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new
            {
                flag.Key,
                flag.Description,
                flag.IsEnabled,
                flag.UpdatedAtUtc
            });
        }

        /// <summary>
        /// Returns recent audit events for student investigations.
        /// </summary>
        /// <param name="take">Maximum number of events (default 100).</param>
        /// <param name="eventType">Optional event type filter.</param>
        [HttpGet("audit")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        public async Task<IActionResult> GetAuditLogs([FromQuery] int take = 100, [FromQuery] string? eventType = null)
        {
            take = Math.Clamp(take, 1, 500);

            var query = _context.AuditLogs.AsQueryable();
            if (!string.IsNullOrWhiteSpace(eventType))
            {
                query = query.Where(a => a.EventType == eventType);
            }

            var logs = await query
                .OrderByDescending(a => a.TimestampUtc)
                .Take(take)
                .Select(a => new
                {
                    a.Id,
                    a.TimestampUtc,
                    a.EventType,
                    a.UserId,
                    a.Severity,
                    a.Details
                })
                .ToListAsync();

            return Ok(logs);
        }

        /// <summary>
        /// Returns guided student mission packs for quality-engineering practice.
        /// </summary>
        [HttpGet("missions")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        public IActionResult GetTrainingMissions()
        {
            var missions = new[]
            {
                new
                {
                    Key = "catalog_integrity",
                    Title = "Catalog Integrity Sweep",
                    Summary = "Validate product catalog behavior, duplicate handling, inactive items, and search consistency.",
                    Persona = "Customer",
                    FocusAreas = new[] { "search", "filtering", "product detail", "data accuracy" },
                    Steps = new[]
                    {
                        "Open the product listing page and search for at least two products.",
                        "Verify active and inactive catalog items behave consistently.",
                        "Inspect a product detail page, then re-run a search to confirm results still render.",
                        "Document any duplicate, missing, or misleading catalog behavior."
                    }
                },
                new
                {
                    Key = "checkout_journey",
                    Title = "Checkout Journey Verification",
                    Summary = "Exercise cart, authentication, saved payment methods, and order creation flows.",
                    Persona = "Customer",
                    FocusAreas = new[] { "cart", "auth", "checkout", "payment methods" },
                    Steps = new[]
                    {
                        "Add two items to the cart and complete a checkout flow.",
                        "Sign in midway and confirm the flow keeps customer data intact.",
                        "Confirm the order appears in order history after submission.",
                        "Check for mismatch between cart totals, order totals, and confirmation state."
                    }
                },
                new
                {
                    Key = "support_workflow",
                    Title = "Support Workflow Drill",
                    Summary = "Investigate returns, support tickets, assignments, and status transitions as a support agent.",
                    Persona = "Support",
                    FocusAreas = new[] { "support cases", "returns", "assignment", "status changes" },
                    Steps = new[]
                    {
                        "Open QA Lab and review seeded return requests and support cases.",
                        "Assign a case and inspect the resulting audit trail.",
                        "Update a return request or case status.",
                        "Identify whether role-based access is enforced correctly."
                    }
                }
            };

            return Ok(missions);
        }

        /// <summary>
        /// Returns personas students can simulate during training.
        /// </summary>
        [HttpGet("personas")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        public IActionResult GetTrainingPersonas()
        {
            var personas = new[]
            {
                new
                {
                    Key = "customer",
                    Label = "Customer",
                    Role = "Customer",
                    Description = "Browse, search, add to cart, checkout, and manage personal account information.",
                    CapabilityNotes = new[] { "Read catalog", "Manage cart", "Place orders", "View own orders" }
                },
                new
                {
                    Key = "support",
                    Label = "Support Agent",
                    Role = "Support",
                    Description = "Handle customer issues, returns, and service cases with controlled workflow access.",
                    CapabilityNotes = new[] { "View support cases", "Assign cases", "Update statuses", "Review returns" }
                },
                new
                {
                    Key = "manager",
                    Label = "Manager",
                    Role = "Manager",
                    Description = "Monitor operational health, scenario packs, and audit telemetry across the training environment.",
                    CapabilityNotes = new[] { "Apply QA packs", "View audit logs", "Oversee support", "Review returns" }
                },
                new
                {
                    Key = "qa_tester",
                    Label = "QA Tester",
                    Role = "QaTester",
                    Description = "Use defect scenarios, audit logs, and mission packs to validate product and workflow quality.",
                    CapabilityNotes = new[] { "Toggle QA flags", "Run missions", "Inspect audits", "Exercise edge cases" }
                }
            };

            return Ok(personas);
        }

        /// <summary>
        /// Returns pre-defined scenario packs for instructor-led training.
        /// </summary>
        [HttpGet("scenario-packs")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        public IActionResult GetScenarioPacks()
        {
            var packs = new[]
            {
                new
                {
                    Key = "happy_path_baseline",
                    Title = "Happy Path Baseline",
                    Description = "Disables intentional defects for baseline validation and regression checks.",
                    FlagSettings = new Dictionary<string, bool>
                    {
                        ["product_duplicate_in_list"] = false,
                        ["order_total_mismatch"] = false,
                        ["auth_email_case_sensitive"] = false,
                        ["returns_refund_delay"] = false,
                        ["support_assignment_conflict"] = false,
                        ["audit_verbose_events"] = true
                    },
                    FocusAreas = new[] { "smoke", "regression", "core checkout" }
                },
                new
                {
                    Key = "data_integrity_hunt",
                    Title = "Data Integrity Hunt",
                    Description = "Enables dataset and totals inconsistencies for investigation exercises.",
                    FlagSettings = new Dictionary<string, bool>
                    {
                        ["product_duplicate_in_list"] = true,
                        ["order_total_mismatch"] = true,
                        ["auth_email_case_sensitive"] = true,
                        ["returns_refund_delay"] = true,
                        ["support_assignment_conflict"] = false,
                        ["audit_verbose_events"] = true
                    },
                    FocusAreas = new[] { "data quality", "api contract", "consistency checks" }
                },
                new
                {
                    Key = "support_ops_breakdown",
                    Title = "Support Ops Breakdown",
                    Description = "Simulates support workflow friction in assignment and refund processes.",
                    FlagSettings = new Dictionary<string, bool>
                    {
                        ["product_duplicate_in_list"] = false,
                        ["order_total_mismatch"] = false,
                        ["auth_email_case_sensitive"] = false,
                        ["returns_refund_delay"] = true,
                        ["support_assignment_conflict"] = true,
                        ["audit_verbose_events"] = true
                    },
                    FocusAreas = new[] { "support triage", "returns", "ops escalation" }
                }
            };

            return Ok(packs);
        }

        /// <summary>
        /// Applies a scenario pack by updating grouped feature flags.
        /// </summary>
        [HttpPost("scenario-packs/{key}/apply")]
        [Authorize(Roles = "Admin,Manager,QaTester")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<IActionResult> ApplyScenarioPack(string key)
        {
            var packs = new Dictionary<string, Dictionary<string, bool>>(StringComparer.OrdinalIgnoreCase)
            {
                ["happy_path_baseline"] = new()
                {
                    ["product_duplicate_in_list"] = false,
                    ["order_total_mismatch"] = false,
                    ["auth_email_case_sensitive"] = false,
                    ["returns_refund_delay"] = false,
                    ["support_assignment_conflict"] = false,
                    ["audit_verbose_events"] = true
                },
                ["data_integrity_hunt"] = new()
                {
                    ["product_duplicate_in_list"] = true,
                    ["order_total_mismatch"] = true,
                    ["auth_email_case_sensitive"] = true,
                    ["returns_refund_delay"] = true,
                    ["support_assignment_conflict"] = false,
                    ["audit_verbose_events"] = true
                },
                ["support_ops_breakdown"] = new()
                {
                    ["product_duplicate_in_list"] = false,
                    ["order_total_mismatch"] = false,
                    ["auth_email_case_sensitive"] = false,
                    ["returns_refund_delay"] = true,
                    ["support_assignment_conflict"] = true,
                    ["audit_verbose_events"] = true
                }
            };

            if (!packs.TryGetValue(key, out var settings))
            {
                return NotFound(new { Message = $"Scenario pack '{key}' was not found." });
            }

            var flags = await _context.QaFeatureFlags.Where(f => settings.Keys.Contains(f.Key)).ToListAsync();
            foreach (var flag in flags)
            {
                flag.IsEnabled = settings[flag.Key];
                flag.UpdatedAtUtc = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();

            return Ok(new
            {
                AppliedPack = key,
                UpdatedFlags = flags.Select(f => new
                {
                    f.Key,
                    f.IsEnabled,
                    f.UpdatedAtUtc
                })
            });
        }

        public class UpdateFlagRequest
        {
            public bool IsEnabled { get; set; }
        }
    }
}
