using System.Text.Json;
using LewisStores.Api.Controllers;
using LewisStores.Api.Data;
using LewisStores.Api.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace LewisStores.Api.Tests;

public class BriefComplianceTests
{
    [Fact]
    public async Task GetProductBySku_ReturnsNotFoundPayload_ForUnknownSku()
    {
        await using var context = CreateContext();
        var controller = new ProductsController(context);

        var result = await controller.GetProductBySku("LEW-UNKNOWN-001");

        var notFound = Assert.IsType<NotFoundObjectResult>(result.Result);
        var payload = JsonSerializer.Serialize(notFound.Value);
        Assert.Contains("not found", payload, StringComparison.OrdinalIgnoreCase);
        Assert.Contains("LEW-UNKNOWN-001", payload, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task ValidatePricing_RejectsZeroValueOrder_WhenZeroValueIsNotAllowed()
    {
        await using var context = CreateContext();
        var controller = new PricingController(context);

        var request = new PricingController.ValidatePricingRequest
        {
            UnitPrice = 0m,
            Quantity = 1,
            VatRate = 0.15m,
            AllowZeroValue = false
        };

        var result = await controller.ValidatePricing(request);

        var badRequest = Assert.IsType<BadRequestObjectResult>(result.Result);
        var payload = JsonSerializer.Serialize(badRequest.Value);
        Assert.Contains("R0.00", payload, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task ValidatePricing_ReturnsVatBreakdown_ForValidOrder()
    {
        await using var context = CreateContext();
        var controller = new PricingController(context);

        var request = new PricingController.ValidatePricingRequest
        {
            UnitPrice = 100m,
            Quantity = 2,
            VatRate = 0.15m,
            AllowZeroValue = false
        };

        var result = await controller.ValidatePricing(request);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        using var document = JsonDocument.Parse(JsonSerializer.Serialize(ok.Value));
        var total = document.RootElement.GetProperty("total").GetDecimal();
        var vatAmount = document.RootElement.GetProperty("vatAmount").GetDecimal();

        Assert.Equal(230m, total);
        Assert.Equal(30m, vatAmount);
    }

    private static AppDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        var context = new AppDbContext(options);
        context.Products.Add(new Product
        {
            Id = "prod-1",
            Title = "Sample Product",
            Description = "Sample product",
            Price = 100m,
            Category = "Furniture",
            CategoryId = "cat-1",
            Image = "https://example.test/image.jpg",
            Sku = "LEW-FUR-0001",
            StockQuantity = 5,
            IsActive = true
        });
        context.SaveChanges();
        return context;
    }
}
