const { defineConfig } = require("cypress");

module.exports = defineConfig({
  projectId: '5nry34',
  allowCypressEnv: true,

  e2e: {
    setupNodeEvents(on, config) {
      // implement node event listeners here
    },
  },
});
