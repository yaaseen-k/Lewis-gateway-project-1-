/// <reference types="cypress" />

/**
 * Lewis-Gateway — Happy Path Demo
 * ---------------------------------------------------------------------------
 * Purpose: record a clean, narratable "everything works" walkthrough for the
 * presentation video — NOT a full regression suite. Assertions are kept
 * light-touch (just enough to confirm each step actually succeeded) so the
 * video reads as a smooth demo rather than a wall of test output.
 *
 * Flow:
 *   1. Land on the homepage
 *   2. Log in with a seeded test customer account
 *   3. Browse to the product catalog
 *   4. Open a specific product
 *   5. Add it to the cart
 *   6. Go to the cart and proceed to checkout
 *   7. Fill in delivery details
 *   8. Fill in payment details and place the order
 *   9. Confirm the order lands in Order History
 *
 * KNOWN RISK: Step 4 (clicking the product card) assumes the whole
 * ProductCard is wrapped in a single clickable link containing the product's
 * title text. If this step fails, the actual click target may differ — send
 * over components/UI.jsx (the ProductCard component) so this selector can be
 * corrected.
 * ---------------------------------------------------------------------------
 */

describe("Lewis-Gateway — Happy Path", () => {
  const CUSTOMER_EMAIL = "test.customer@lewisstores.local";
  const CUSTOMER_PASSWORD = "Password123!";
  const DEMO_PRODUCT_TITLE = "Ergonomic Standing Desk";

  // Small helper matching the app's consistent form-group markup:
  // <div class="form-group"><label class="form-label">X</label><input .../></div>
  const fillFormGroup = (labelText, value) => {
    cy.contains(".form-group", labelText).find("input").clear().type(value);
  };

  it("completes a full purchase as a logged-in customer", () => {
    // -------------------------------------------------------------------
    // 1. Homepage
    // -------------------------------------------------------------------
    cy.visit("http://localhost:3000/");
    cy.contains("Furnish Your Home").should("be.visible");

    // -------------------------------------------------------------------
    // 2. Log in
    // -------------------------------------------------------------------
    cy.visit("/auth");
    cy.contains("h1", "Sign In").should("be.visible");

    fillFormGroup("Email", CUSTOMER_EMAIL);
    fillFormGroup("Password", CUSTOMER_PASSWORD);
    cy.contains("button", "Log In").click();

    // AuthPage auto-redirects to /profile once isAuthenticated flips true
    cy.url().should("include", "/profile");

    // -------------------------------------------------------------------
    // 3. Browse to the product catalog
    // -------------------------------------------------------------------
    cy.visit("/products");
    cy.contains("h1", "All Products").should("be.visible");

    // -------------------------------------------------------------------
    // 4. Open a specific product
    // -------------------------------------------------------------------
    // NOTE: assumes the ProductCard renders the title as clickable text
    // inside a link wrapping the whole card. See risk note at top of file.
    cy.contains(DEMO_PRODUCT_TITLE).click();
    cy.contains("h1", DEMO_PRODUCT_TITLE).should("be.visible");

    // -------------------------------------------------------------------
    // 5. Add to cart
    // -------------------------------------------------------------------
    cy.contains("button", "Add to Cart").click();

    // -------------------------------------------------------------------
    // 6. Cart -> Checkout
    // -------------------------------------------------------------------
    cy.visit("/cart");
    cy.contains("h1", "Shopping Cart").should("be.visible");
    cy.contains(DEMO_PRODUCT_TITLE).should("be.visible");

    cy.contains("Proceed to Checkout").click();
    cy.url().should("include", "/checkout");

    // -------------------------------------------------------------------
    // 7. Delivery Information (Checkout step 0)
    // -------------------------------------------------------------------
    cy.contains("h2", "Delivery Information").should("be.visible");

    fillFormGroup("Full Name", "Thabo Nkosi");
    fillFormGroup("Phone Number", "0820000000");
    fillFormGroup("Street Address", "12 Mandela Street, Sandton");
    fillFormGroup("City", "Johannesburg");
    fillFormGroup("Postal Code", "2196");

    cy.contains("button", "Continue to Payment").click();

    // -------------------------------------------------------------------
    // 8. Payment Details (Checkout step 1) -> Place Order
    // -------------------------------------------------------------------
    cy.contains("h2", "Payment Details").should("be.visible");

    fillFormGroup("Card Number", "4111111111111111");
    fillFormGroup("Expiry Date", "12/29");
    fillFormGroup("CVV", "123");

    cy.contains("button", "Place Order").click();

    // -------------------------------------------------------------------
    // 9. Confirm order landed in Order History
    // -------------------------------------------------------------------
    // placeOrder() navigates to /orders on success and clears the cart.
    cy.url().should("include", "/orders", { timeout: 10000 });
    cy.contains("h1", "Order History").should("be.visible");

    // The most recent order should now appear in the table.
    cy.get("table").should("contain.text", DEMO_PRODUCT_TITLE);
  });
});
