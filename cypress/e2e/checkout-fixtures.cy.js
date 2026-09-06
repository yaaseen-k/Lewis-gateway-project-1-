describe('SauceDemo checkout using fixtures', () => {
  let customer;
  let sku;
  let delivery;

  before(() => {

    // Load customer fixture
    cy.fixture('customers').then((data) => {
      customer = data.customers.find(
        (customer) => customer.id === 'CUST-001'
      );
    });

    // Load SKU fixture
    cy.fixture('sku').then((data) => {
      sku = data.products.find(
        (product) => product.sku === 'SKU-001'
      );
    });

    // Load delivery fixture
    cy.fixture('delivery').then((data) => {
      delivery = data.deliveryDetails.find(
        (details) => details.customerId === 'CUST-001'
      );
    });
  });

  it('logs in, adds an item to the cart, and enters delivery details', () => {

    // -----------------------------
    // LOGIN
    // -----------------------------

    cy.visit('https://www.saucedemo.com/');

    cy.get('[data-test="username"]')
      .should('be.visible')
      .type(customer.username);

    cy.get('[data-test="password"]')
      .should('be.visible')
      .type(customer.password, { log: false });

    cy.get('[data-test="login-button"]')
      .click();

    cy.url()
      .should('include', '/inventory.html');


    // -----------------------------
    // ADD ITEM TO CART
    // -----------------------------

    cy.get(sku.cartButton)
      .should('be.visible')
      .click();

    cy.get('.shopping_cart_badge')
      .should('have.text', '1');


    // -----------------------------
    // OPEN CART
    // -----------------------------

    cy.get('[data-test="shopping-cart-link"]')
      .click();

    cy.contains('.inventory_item_name', sku.name)
      .should('be.visible');


    // -----------------------------
    // START CHECKOUT
    // -----------------------------

    cy.get('[data-test="checkout"]')
      .click();


    // -----------------------------
    // ENTER DELIVERY DETAILS
    // -----------------------------

    cy.get('[data-test="firstName"]')
      .should('be.visible')
      .type(delivery.customerName.split(' ')[0]);

    cy.get('[data-test="lastName"]')
      .should('be.visible')
      .type(delivery.customerName.split(' ')[1]);

    cy.get('[data-test="postalCode"]')
      .should('be.visible')
      .type(delivery.postalCode);


    // -----------------------------
    // CONTINUE
    // -----------------------------

    cy.get('[data-test="continue"]')
      .click();


    // -----------------------------
    // VERIFY CHECKOUT
    // -----------------------------

    cy.get('.cart_item')
      .should('contain.text', sku.name);

    cy.get('[data-test="finish"]')
      .should('be.visible');
  });
});