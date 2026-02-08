FROM lscr.io/linuxserver/chromium:latest

# Install Node.js 22 for Playwright MCP server
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g @playwright/mcp@latest && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy init scripts
COPY custom-cont-init.d/50-build-chrome-cli.sh /custom-cont-init.d/50-build-chrome-cli
COPY clean-singletonlock.sh /custom-cont-init.d/99-clean-singletonlock
