const { defineConfig } = require('@playwright/test')

module.exports = defineConfig({
  testDir: './tests/browser',
  timeout: 60000,
  use: { baseURL: 'http://127.0.0.1:4001', headless: true },
  webServer: {
    command: "node -e \"const fs=require('fs');for(const f of ['/tmp/storybook-e2e.db','/tmp/storybook-e2e.db-wal','/tmp/storybook-e2e.db-shm'])try{fs.unlinkSync(f)}catch{}\" && DB=/tmp/storybook-e2e.db PORT=4001 npm start",
    url: 'http://127.0.0.1:4001/api/health',
    reuseExistingServer: false,
    timeout: 30000,
  },
})
