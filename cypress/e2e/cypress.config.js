const { defineConfig } = require("cypress");

module.exports = defineConfig({
  e2e: {
    baseUrl: "http://localhost:3000",
    setupNodeEvents(on, config) {
      // no custom node event handlers needed for this spec
      return config;
    },
  },

  // Recording settings — this is what produces the video for your presentation.
  video: true,               // record every spec run
  videoCompression: 32,      // 0-51, lower = higher quality/larger file. 32 is a good balance.
  videosFolder: "cypress/videos",

  viewportWidth: 1280,
  viewportHeight: 800,

  defaultCommandTimeout: 8000, // a little generous, since some pages fetch from the API on load
});
