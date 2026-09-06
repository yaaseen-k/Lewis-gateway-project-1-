using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LewisStores.Api.Data;
using LewisStores.Api.Models;

namespace LewisStores.Api.Controllers
{
    /// <summary>
    /// Handles credit application workflows.
    /// </summary>
    [Route("api/[controller]")]
    [ApiController]
    public class CreditController : ControllerBase
    {
        private readonly AppDbContext _context;

        public CreditController(AppDbContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Returns all submitted credit applications.
        /// </summary>
        [HttpGet]
        [ProducesResponseType(typeof(IEnumerable<CreditApplication>), StatusCodes.Status200OK)]
        public async Task<ActionResult<IEnumerable<CreditApplication>>> GetApplications()
        {
            return await _context.CreditApplications.ToListAsync();
        }

        /// <summary>
        /// Submits a new credit application.
        /// </summary>
        /// <param name="application">Credit application payload.</param>
        [HttpPost]
        [ProducesResponseType(typeof(CreditApplication), StatusCodes.Status201Created)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<ActionResult<CreditApplication>> Apply([FromBody] CreditApplication application)
        {
            application.Status = "Pending Review";
            application.ApplicationDate = DateTime.UtcNow;

            _context.CreditApplications.Add(application);
            await _context.SaveChangesAsync();
            return CreatedAtAction(nameof(GetApplications), new { id = application.Id }, application);
        }
    }
}
