using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using LewisStores.Api.Data;
using LewisStores.Api.Models;

namespace LewisStores.Api.Controllers
{
    /// <summary>
    /// Provides instructor and student training operations for mission tracking and defect reporting.
    /// </summary>
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class TrainingController : ControllerBase
    {
        private readonly AppDbContext _context;

        public TrainingController(AppDbContext context)
        {
            _context = context;
        }

        public class StartMissionRequest
        {
            public string MissionKey { get; set; } = string.Empty;
            public string PersonaKey { get; set; } = "customer";
        }

        public class CompleteMissionRequest
        {
            public string MissionKey { get; set; } = string.Empty;
            public string PersonaKey { get; set; } = "customer";
            public int FindingsCount { get; set; }
            public int? Score { get; set; }
        }

        public class CreateDefectReportRequest
        {
            public string MissionKey { get; set; } = string.Empty;
            public string Title { get; set; } = string.Empty;
            public string Severity { get; set; } = "Medium";
            public string StepsToReproduce { get; set; } = string.Empty;
            public string ExpectedResult { get; set; } = string.Empty;
            public string ActualResult { get; set; } = string.Empty;
            public string EnvironmentNotes { get; set; } = string.Empty;
        }

        public class ReviewDefectReportRequest
        {
            public string Status { get; set; } = string.Empty;
            public string InstructorFeedback { get; set; } = string.Empty;
            public int? Score { get; set; }
        }

        public class ResetSessionRequest
        {
            public string ScenarioPackKey { get; set; } = "happy_path_baseline";
            public bool ClearStudentData { get; set; } = true;
            public bool ClearAudit { get; set; }
        }

        [HttpGet("missions/progress")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        public async Task<IActionResult> GetMissionProgress()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            var isStaff = IsStaff();
            var query = _context.MissionProgresses.AsQueryable();
            if (!isStaff)
            {
                query = query.Where(m => m.UserId == userId);
            }

            var data = await query
                .OrderByDescending(m => m.CompletedAtUtc ?? m.StartedAtUtc)
                .Select(m => new
                {
                    m.Id,
                    m.MissionKey,
                    m.UserId,
                    m.PersonaKey,
                    m.Status,
                    m.Score,
                    m.Badge,
                    m.StartedAtUtc,
                    m.CompletedAtUtc
                })
                .ToListAsync();

            return Ok(data);
        }

        [HttpPost("missions/start")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> StartMission([FromBody] StartMissionRequest request)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            if (string.IsNullOrWhiteSpace(request.MissionKey))
            {
                return BadRequest(new { Message = "MissionKey is required." });
            }

            var progress = await _context.MissionProgresses
                .FirstOrDefaultAsync(m => m.UserId == userId && m.MissionKey == request.MissionKey);

            if (progress == null)
            {
                progress = new MissionProgress
                {
                    UserId = userId,
                    MissionKey = request.MissionKey.Trim(),
                    PersonaKey = string.IsNullOrWhiteSpace(request.PersonaKey) ? "customer" : request.PersonaKey,
                    Status = "InProgress",
                    StartedAtUtc = DateTime.UtcNow,
                    Score = 0,
                    Badge = "None"
                };
                _context.MissionProgresses.Add(progress);
            }
            else
            {
                progress.Status = "InProgress";
                progress.PersonaKey = string.IsNullOrWhiteSpace(request.PersonaKey) ? progress.PersonaKey : request.PersonaKey;
                progress.StartedAtUtc = DateTime.UtcNow;
                progress.CompletedAtUtc = null;
            }

            await _context.SaveChangesAsync();
            await WriteAuditAsync("training.mission.started", userId, "Info", $"{{\"missionKey\":\"{request.MissionKey}\"}}");

            return Ok(new
            {
                progress.Id,
                progress.MissionKey,
                progress.Status,
                progress.PersonaKey,
                progress.StartedAtUtc
            });
        }

        [HttpPost("missions/complete")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> CompleteMission([FromBody] CompleteMissionRequest request)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            if (string.IsNullOrWhiteSpace(request.MissionKey))
            {
                return BadRequest(new { Message = "MissionKey is required." });
            }

            var progress = await _context.MissionProgresses
                .FirstOrDefaultAsync(m => m.UserId == userId && m.MissionKey == request.MissionKey)
                ?? new MissionProgress
                {
                    UserId = userId,
                    MissionKey = request.MissionKey.Trim(),
                    StartedAtUtc = DateTime.UtcNow
                };

            if (progress.Id == 0)
            {
                _context.MissionProgresses.Add(progress);
            }

            var computedScore = request.Score ?? Math.Clamp(45 + (request.FindingsCount * 12), 0, 100);
            progress.Status = "Completed";
            progress.PersonaKey = string.IsNullOrWhiteSpace(request.PersonaKey) ? progress.PersonaKey : request.PersonaKey;
            progress.Score = Math.Clamp(computedScore, 0, 100);
            progress.Badge = progress.Score switch
            {
                >= 90 => "Platinum",
                >= 80 => "Gold",
                >= 70 => "Silver",
                >= 60 => "Bronze",
                _ => "Participant"
            };
            progress.CompletedAtUtc = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            await WriteAuditAsync("training.mission.completed", userId, "Info", $"{{\"missionKey\":\"{request.MissionKey}\",\"score\":{progress.Score},\"badge\":\"{progress.Badge}\"}}");

            return Ok(new
            {
                progress.Id,
                progress.MissionKey,
                progress.Status,
                progress.Score,
                progress.Badge,
                progress.CompletedAtUtc
            });
        }

        [HttpGet("missions/leaderboard")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        public async Task<IActionResult> GetMissionLeaderboard()
        {
            var leaderboard = await _context.MissionProgresses
                .Where(m => m.Status == "Completed")
                .GroupBy(m => m.UserId)
                .Select(g => new
                {
                    UserId = g.Key,
                    MissionsCompleted = g.Count(),
                    AverageScore = (int)Math.Round(g.Average(x => x.Score)),
                    BestBadge = g.OrderByDescending(x => x.Score).Select(x => x.Badge).FirstOrDefault() ?? "Participant"
                })
                .OrderByDescending(x => x.AverageScore)
                .ThenByDescending(x => x.MissionsCompleted)
                .Take(20)
                .ToListAsync();

            var userMap = await _context.Users
                .Where(u => leaderboard.Select(x => x.UserId).Contains(u.Id))
                .ToDictionaryAsync(u => u.Id, u => new { u.FullName, u.Role });

            var result = leaderboard.Select(entry =>
            {
                userMap.TryGetValue(entry.UserId, out var user);
                return new
                {
                    entry.UserId,
                    FullName = user?.FullName ?? entry.UserId,
                    Role = user?.Role ?? "Unknown",
                    entry.MissionsCompleted,
                    entry.AverageScore,
                    entry.BestBadge
                };
            });

            return Ok(result);
        }

        [HttpGet("defect-reports")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        public async Task<IActionResult> GetDefectReports()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            var query = _context.DefectReports.AsQueryable();
            if (!IsStaff())
            {
                query = query.Where(r => r.SubmittedByUserId == userId);
            }

            var reports = await query
                .OrderByDescending(r => r.SubmittedAtUtc)
                .Select(r => new
                {
                    r.Id,
                    r.MissionKey,
                    r.Title,
                    r.Severity,
                    r.Status,
                    r.SubmittedByUserId,
                    r.SubmittedAtUtc,
                    r.Score,
                    r.InstructorFeedback
                })
                .ToListAsync();

            return Ok(reports);
        }

        [HttpPost("defect-reports")]
        [ProducesResponseType(StatusCodes.Status201Created)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> CreateDefectReport([FromBody] CreateDefectReportRequest request)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            if (string.IsNullOrWhiteSpace(request.MissionKey) || string.IsNullOrWhiteSpace(request.Title) || string.IsNullOrWhiteSpace(request.StepsToReproduce))
            {
                return BadRequest(new { Message = "MissionKey, title, and reproduction steps are required." });
            }

            var entity = new DefectReport
            {
                MissionKey = request.MissionKey.Trim(),
                Title = request.Title.Trim(),
                Severity = string.IsNullOrWhiteSpace(request.Severity) ? "Medium" : request.Severity.Trim(),
                StepsToReproduce = request.StepsToReproduce.Trim(),
                ExpectedResult = request.ExpectedResult?.Trim() ?? string.Empty,
                ActualResult = request.ActualResult?.Trim() ?? string.Empty,
                EnvironmentNotes = request.EnvironmentNotes?.Trim() ?? string.Empty,
                Status = "Submitted",
                SubmittedByUserId = userId,
                SubmittedAtUtc = DateTime.UtcNow
            };

            _context.DefectReports.Add(entity);
            await _context.SaveChangesAsync();
            await WriteAuditAsync("training.defect.submitted", userId, "Info", $"{{\"reportId\":{entity.Id},\"missionKey\":\"{entity.MissionKey}\"}}");

            return CreatedAtAction(nameof(GetDefectReports), new { id = entity.Id }, entity);
        }

        [HttpPut("defect-reports/{id:int}/review")]
        [Authorize(Roles = "Admin,Manager,Support,QaTester")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<IActionResult> ReviewDefectReport(int id, [FromBody] ReviewDefectReportRequest request)
        {
            var report = await _context.DefectReports.FirstOrDefaultAsync(r => r.Id == id);
            if (report == null)
            {
                return NotFound(new { Message = "Defect report not found." });
            }

            report.Status = string.IsNullOrWhiteSpace(request.Status) ? report.Status : request.Status.Trim();
            report.InstructorFeedback = request.InstructorFeedback?.Trim() ?? report.InstructorFeedback;
            report.Score = request.Score ?? report.Score;

            await _context.SaveChangesAsync();
            await WriteAuditAsync("training.defect.reviewed", User.FindFirstValue(ClaimTypes.NameIdentifier), "Info", $"{{\"reportId\":{id},\"status\":\"{report.Status}\"}}");

            return Ok(new
            {
                report.Id,
                report.Status,
                report.Score,
                report.InstructorFeedback
            });
        }

        [HttpPost("session/reset")]
        [Authorize(Roles = "Admin,Manager,QaTester")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<IActionResult> ResetSession([FromBody] ResetSessionRequest request)
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

            if (!packs.TryGetValue(request.ScenarioPackKey, out var settings))
            {
                return NotFound(new { Message = $"Scenario pack '{request.ScenarioPackKey}' was not found." });
            }

            var flags = await _context.QaFeatureFlags.Where(f => settings.Keys.Contains(f.Key)).ToListAsync();
            foreach (var flag in flags)
            {
                flag.IsEnabled = settings[flag.Key];
                flag.UpdatedAtUtc = DateTime.UtcNow;
            }

            if (request.ClearStudentData)
            {
                _context.DefectReports.RemoveRange(_context.DefectReports);
                _context.MissionProgresses.RemoveRange(_context.MissionProgresses);
            }

            if (request.ClearAudit)
            {
                _context.AuditLogs.RemoveRange(_context.AuditLogs);
            }

            await _context.SaveChangesAsync();
            await WriteAuditAsync("training.session.reset", User.FindFirstValue(ClaimTypes.NameIdentifier), "Warning", $"{{\"scenarioPack\":\"{request.ScenarioPackKey}\",\"clearStudentData\":{request.ClearStudentData.ToString().ToLowerInvariant()},\"clearAudit\":{request.ClearAudit.ToString().ToLowerInvariant()}}}");

            return Ok(new
            {
                ScenarioPack = request.ScenarioPackKey,
                request.ClearStudentData,
                request.ClearAudit,
                UpdatedFlags = flags.Select(f => new { f.Key, f.IsEnabled, f.UpdatedAtUtc })
            });
        }

        private bool IsStaff()
        {
            return User.IsInRole("Admin") || User.IsInRole("Manager") || User.IsInRole("Support") || User.IsInRole("QaTester");
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
