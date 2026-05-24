# ── Stage 1: Base ──────────────────────────────────────
# Start from official Node.js 18 image (slim = smaller size)
FROM node:18-alpine AS base

# Set working directory inside the container
WORKDIR /app

# Copy package files first (before copying code)
# Why? Docker caches layers. If packages didn't change,
# it skips reinstalling them — makes builds much faster
COPY package*.json ./

# ── Stage 2: Dependencies ──────────────────────────────
FROM base AS dependencies

# Install only production dependencies
# No jest, nodemon etc — keeps container lean
RUN npm ci --only=production

# ── Stage 3: Final Image ───────────────────────────────
FROM base AS final

# Copy production node_modules from previous stage
COPY --from=dependencies /app/node_modules ./node_modules

# Now copy your actual source code
COPY src/ ./src/

# Tell Docker this container listens on port 3000
EXPOSE 3000

# The command that runs when container starts
CMD ["node", "src/index.js"]
