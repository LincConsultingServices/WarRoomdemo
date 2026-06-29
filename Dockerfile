FROM node:20-alpine AS builder

WORKDIR /app

# NEXT_PUBLIC_* values are inlined into the JS bundle at build time (they are NOT
# read at runtime), so the backend URL MUST be present here as a build arg.
# cloudbuild.yaml passes it via --build-arg from the _NEXT_PUBLIC_API_URL
# substitution. The default below points at the live backend so a plain
# `docker build` (no --build-arg) still produces a working bundle.
ARG NEXT_PUBLIC_API_URL=https://warroom-backend-git-262374983592.us-central1.run.app/api
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL

# Install dependencies (dev deps included — babel-plugin-react-compiler is
# required by the reactCompiler build).
COPY package.json package-lock.json ./
RUN npm ci

# Copy source and build the Next.js app
COPY . .
RUN npm run build

# ── Runtime stage ─────────────────────────────────────────────────────────────
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000

# Copy the built app and the files `next start` needs at runtime
COPY --from=builder /app/next.config.ts ./
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

EXPOSE 3000

CMD ["npm", "start"]
