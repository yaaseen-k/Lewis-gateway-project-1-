// ***********************************************
// This example commands.js shows you how to
// create various custom commands and overwrite
// existing commands.
//
// For more comprehensive examples of custom
// commands please read more here:
// https://on.cypress.io/custom-commands
// ***********************************************
//
//
// -- This is a parent command --
// Cypress.Commands.add('login', (email, password) => { ... })
//
//
// -- This is a child command --
// Cypress.Commands.add('drag', { prevSubject: 'element'}, (subject, options) => { ... })
//
//
// -- This is a dual command --
// Cypress.Commands.add('dismiss', { prevSubject: 'optional'}, (subject, options) => { ... })
//
//
// -- This will overwrite an existing command --
// Cypress.Commands.overwrite('visit', (originalFn, url, options) => { ... })

//Example of a custom command to login
// Cypress.Commands.add("login", (username, password) => {
//   cy.visit("/login");
//   cy.get('[data-testid="username"]').type(username);
//   cy.get('[data-testid="password"]').type(password);
//   cy.get('[data-testid="login-btn"]').click();
//   cy.get('[data-testid="dashboard"]').should("be.visible");
// });

//Test call
//cy.login(Cypress.env("username"), Cypress.env("password"));