# EF Migration instructions: Add OrderItems

This file shows the recommended commands and a sample migration scaffold to add the `OrderItems` table for the normalized Orders → OrderItems → Products model.

1. Install the EF Core CLI (if not already installed):

```bash
dotnet tool install --global dotnet-ef
```

2. From the repository root (where `LewisStores.Api.csproj` is located), add a migration:

```bash
cd Lewis-Stores/LewisStores.Api
dotnet ef migrations add AddOrderItemsTable -o Migrations
```

3. Inspect the generated migration under `Migrations/` and then apply it to the database:

```bash
dotnet ef database update
```

4. If you use a separate startup project, pass `-s` and `-p` accordingly.

---

Sample migration skeleton (example only) to create `OrderItems` table. The EF CLI will generate similar code automatically; paste into the generated migration's `Up` method if you prefer to hand-edit.

```csharp
protected override void Up(MigrationBuilder migrationBuilder)
{
    migrationBuilder.CreateTable(
        name: "OrderItems",
        columns: table => new
        {
            Id = table.Column<int>(nullable: false)
                .Annotation("SqlServer:Identity", "1, 1"),
            OrderId = table.Column<string>(nullable: false),
            ProductId = table.Column<string>(nullable: false),
            Quantity = table.Column<int>(nullable: false),
            UnitPrice = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
            LineTotal = table.Column<decimal>(type: "decimal(18,2)", nullable: false)
        },
        constraints: table =>
        {
            table.PrimaryKey("PK_OrderItems", x => x.Id);
            table.ForeignKey(
                name: "FK_OrderItems_Orders_OrderId",
                column: x => x.OrderId,
                principalTable: "Orders",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
            table.ForeignKey(
                name: "FK_OrderItems_Products_ProductId",
                column: x => x.ProductId,
                principalTable: "Products",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        });

    migrationBuilder.CreateIndex(
        name: "IX_OrderItems_OrderId",
        table: "OrderItems",
        column: "OrderId");

    migrationBuilder.CreateIndex(
        name: "IX_OrderItems_ProductId",
        table: "OrderItems",
        column: "ProductId");
}
```

Notes:
- The codebase currently seeds `Order` objects and we added `OrderItem` model/seed. Run a migration to create the table before running the app.
- After applying migration, run the app to let EF Core apply seeding if using `EnsureCreated` or run seed code paths.
- Update API DTOs/controllers to return `OrderItems` as structured lines instead of parsing `Items` strings.
