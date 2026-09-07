/// <reference types="cypress" />

/**
 * Lewis-Gateway — Happy Path Demo
---------------------------------------------------------------------------
 */

describe("Lewis-Gateway — Happy Path", () => {
  const CUSTOMER_EMAIL = "test.customer@lewisstores.local";
  const CUSTOMER_PASSWORD = "Password123!";
  const DEMO_PRODUCT_TITLE = "Ergonomic Standing Desk";


  const fillFormGroup = (labelText, value) => {
    cy.contains(".form-group", labelText).find("input").clear().type(value);
  };

  it("completes a full purchase as a logged-in customer", () => {
  
    cy.visit("http://localhost:3000/");
    cy.contains("Furnish Your Home").should("be.visible");

   
    cy.visit("/auth");
    cy.contains("h1", "Sign In").should("be.visible");

    fillFormGroup("Email", CUSTOMER_EMAIL);
    fillFormGroup("Password", CUSTOMER_PASSWORD);
    cy.contains("button", "Log In").click();

    
    cy.url().should("include", "/profile");

  
    cy.visit("/products");
    cy.contains("h1", "All Products").should("be.visible");

  
    cy.contains(DEMO_PRODUCT_TITLE).click();
    cy.contains("h1", DEMO_PRODUCT_TITLE).should("be.visible");

  
    cy.contains("button", "Add to Cart").click();


    cy.visit("/cart");
    cy.contains("h1", "Shopping Cart").should("be.visible");
    cy.contains(DEMO_PRODUCT_TITLE).should("be.visible");

    cy.contains("Proceed to Checkout").click();
    cy.url().should("include", "/checkout");


    cy.contains("h2", "Delivery Information").should("be.visible");

    fillFormGroup("Full Name", "Thabo Nkosi");
    fillFormGroup("Phone Number", "0820000000");
    fillFormGroup("Street Address", "12 Mandela Street, Sandton");
    fillFormGroup("City", "Johannesburg");
    fillFormGroup("Postal Code", "2196");

    cy.contains("button", "Continue to Payment").click();

 
    cy.contains("h2", "Payment Details").should("be.visible");

    fillFormGroup("Card Number", "4111111111111111");
    fillFormGroup("Expiry Date", "12/29");
    fillFormGroup("CVV", "123");

    cy.contains("button", "Place Order").click();

   
   
    cy.url().should("include", "/orders", { timeout: 10000 });
    cy.contains("h1", "Order History").should("be.visible");

   
    cy.get("table").should("contain.text", DEMO_PRODUCT_TITLE);
  });
});
