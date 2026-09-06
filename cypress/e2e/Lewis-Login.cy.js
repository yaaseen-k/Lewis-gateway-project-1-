describe('logging in to lewis project website', () => {

    beforeEach(() => {

        // Intercept the actual login API
        cy.intercept('POST','**/api/Auth/login').as('login');

        // Open the website
        cy.visit('http://localhost:3000/profile');
    });


    it('Intercepts the login request and checks the response', () => {

        // Go to login page
        cy.get('a[href="/auth"]')
            .first()
            .click();

        // Enter email
        cy.get('input[type="email"]')
            .should('be.visible')
            .type('james.brown@lewisstores.local');

        // Enter password
        cy.get('input[type="password"]')
            .should('be.visible')
            .type('Password123!', { log: false });

        // Click login
        cy.get('button[type="submit"]')
            .should('be.visible')
            .click();

        // Wait for login API
        cy.wait('@login', { timeout: 10000 })
            .then(({ request, response }) => {

                // Check the request body
                expect(request.body)
                    .to.have.property(
                        'email',
                        'james.brown@lewisstores.local'
                    );

                expect(request.body)
                    .to.have.property(
                        'password',
                        'Password123!'
                    );

                // Check the response
                expect(response.statusCode)
                    .to.eq(200);
            });
    });

});