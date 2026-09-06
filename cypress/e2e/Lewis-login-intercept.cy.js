describe('Login - Network Interception', () => {

  beforeEach(() => {

    cy.intercept('POST', '**/api/auth/login').as('login');

    cy.intercept('GET', '**/api/pricing/**').as('price');

    cy.intercept('GET', '**/api/stock/**').as('stock');

    cy.intercept('POST', '**/api/delivery/quote').as('deliveryQuote');

    cy.intercept('POST', '**/api/checkout').as('checkout');

    cy.visit('http://localhost:3000');
  });


  it('logs in and validates checkout API contracts', () => {

    // Login
    cy.get('[data-testid="email-input"]')
      .type('james.brown@lewisstores.local');

    cy.get('[data-testid="password-input"]')
      .type('Password123!', { log: false });

    cy.get('[data-testid="login-button"]')
      .click();

    cy.wait('@login').then(({ response }) => {
      expect(response.statusCode).to.eq(200);
    });


    // Product
    cy.get('[data-testid="sku-input"]')
      .clear()
      .type('SKU-003');

    cy.get('[data-testid="load-product"]')
      .click();


    // Price contract
    cy.wait('@price').then(({ response }) => {

      expect(response.statusCode).to.eq(200);

      expect(response.body)
        .to.have.property('unitPrice');

      expect(response.body.unitPrice)
        .to.be.a('number');
    });


    // Stock contract
    cy.wait('@stock').then(({ response }) => {

      expect(response.statusCode).to.eq(200);

      expect(response.body)
        .to.have.property('availableQty');

      expect(response.body.availableQty)
        .to.be.a('number');
    });


    // Delivery
    cy.get('[data-testid="distance-input"]')
      .clear()
      .type('10');

    cy.get('[data-testid="weight-input"]')
      .clear()
      .type('50');

    cy.get('[data-testid="btn-delivery-quote"]')
      .click();


    cy.wait('@deliveryQuote').then(({ request, response }) => {

      expect(request.body).to.include({
        distanceKm: 10,
        weightKg: 50
      });

      expect(response.statusCode).to.eq(200);

      expect(response.body.deliveryFee)
        .to.be.a('number');
    });


    // Checkout
    cy.get('[data-testid="complete-checkout"]')
      .click();

    cy.wait('@checkout').then(({ request, response }) => {

      expect(request.body).to.exist;

      expect(response.statusCode).to.eq(200);
    });

  });

});