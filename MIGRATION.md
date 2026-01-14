# Migration Guide: nestjs-rest-microservices

This document describes all changes made to migrate the original repository to support modern Node.js (v24+) and updated dependencies.

## Overview

The original repository used the deprecated native `grpc` package, which doesn't compile on Node.js v17+. This migration updates the project to use `@grpc/grpc-js` (pure JavaScript implementation) and upgrades NestJS from v6.x to v8.x.

---

## 1. gRPC Package Migration

### Problem
The native `grpc` package was deprecated in April 2021 and has no prebuilt binaries for Node.js v17+.

### Solution
Replaced `grpc` with `@grpc/grpc-js` in all services.

**Files changed:**
- `api-gateway/package.json`
- `microservices/comments-svc/package.json`
- `microservices/organizations-svc/package.json`
- `microservices/users-svc/package.json`

```diff
- "grpc": "^1.24.0"
+ "@grpc/grpc-js": "^1.9.0",
+ "@grpc/proto-loader": "^0.7.0"
```

---

## 2. gRPC Credentials Configuration

### Problem
`@grpc/grpc-js` requires explicit credentials configuration, unlike the native package.

### Solution
Added credentials to microservice servers and API gateway clients.

**Microservice main.ts files** (`microservices/*/src/main.ts`):
```typescript
import * as grpc from '@grpc/grpc-js'

const app = await NestFactory.createMicroservice(AppModule, {
  transport: Transport.GRPC,
  options: {
    // ... other options
    credentials: grpc.ServerCredentials.createInsecure()
  }
})
```

**API Gateway client options** (`api-gateway/src/*-svc.options.ts`):
```typescript
import * as grpc from '@grpc/grpc-js'

export const ServiceClientOptions: ClientOptions = {
  transport: Transport.GRPC,
  options: {
    // ... other options
    credentials: grpc.credentials.createInsecure()
  }
}
```

---

## 3. NestJS Upgrade (v6.x/v7.x to v8.x)

### Problem
NestJS v6.x and v7.x attempt to load the native `grpc` package first. Only v8.x uses `@grpc/grpc-js` by default.

### Solution
Upgraded all NestJS packages to v8.x.

**Files changed:** All `package.json` files

```diff
# Dependencies
- "@nestjs/common": "^6.10.14"
- "@nestjs/config": "^0.6.3"
- "@nestjs/core": "^6.10.14"
- "@nestjs/microservices": "^6.10.14"
+ "@nestjs/common": "^8.4.7"
+ "@nestjs/config": "^1.2.1"
+ "@nestjs/core": "^8.4.7"
+ "@nestjs/microservices": "^8.4.7"

# API Gateway only
- "@nestjs/platform-express": "^6.10.14"
+ "@nestjs/platform-express": "^8.4.7"

# Dev Dependencies
- "@nestjs/cli": "^6.13.2"
- "@nestjs/schematics": "^6.8.1"
- "@nestjs/testing": "^6.10.14"
+ "@nestjs/cli": "^8.2.8"
+ "@nestjs/schematics": "^8.0.11"
+ "@nestjs/testing": "^8.4.7"
```

---

## 4. Pino Logger Upgrade

### Problem
`nestjs-pino` v2.x (required for NestJS 8.x) needs `pino-http` as a peer dependency.

### Solution
Upgraded pino packages and added `pino-http`.

**Files changed:** All `package.json` files

```diff
- "nestjs-pino": "^1.4.0"
- "pino": "^6.14.0"
+ "nestjs-pino": "^2.6.0"
+ "pino": "^7.11.0"
+ "pino-http": "^6.6.0"  # Added to microservices
```

---

## 5. RxJS Upgrade

### Problem
NestJS 8.x requires RxJS 7.x.

### Solution
Upgraded RxJS in all services.

```diff
- "rxjs": "^6.6.7"
+ "rxjs": "^7.5.5"
```

---

## 6. TypeScript Upgrade

### Problem
TypeScript 3.7.5 doesn't support `import type` syntax used by newer packages.

### Solution
Upgraded TypeScript to 4.9.5.

**Files changed:** All `package.json` files

```diff
- "typescript": "3.7.5"
+ "typescript": "4.9.5"
```

---

## 7. TypeScript Configuration

### Problem
Type errors in node_modules from incompatible type definitions.

### Solution
Added `skipLibCheck` to all TypeScript configurations.

**Files changed:**
- `api-gateway/tsconfig.json`
- `microservices/comments-svc/tsconfig.json`
- `microservices/organizations-svc/tsconfig.json`
- `microservices/users-svc/tsconfig.json`

```diff
{
  "compilerOptions": {
    // ... existing options
+   "skipLibCheck": true
  }
}
```

---

## 8. ESLint Configuration

### Problem
ESLint `import/named` rule produced false positives with `@grpc/grpc-js`.

### Solution
Disabled the rule in all ESLint configurations.

**Files changed:**
- `api-gateway/.eslintrc.yaml`
- `microservices/comments-svc/.eslintrc.yaml`
- `microservices/organizations-svc/.eslintrc.yaml`
- `microservices/users-svc/.eslintrc.yaml`

```diff
rules:
  # ... existing rules
+ import/named: 0
```

---

## 9. Install Script Fixes

### Problem
Shell scripts used relative paths that failed when run from different directories.

### Solution
Changed to absolute paths and added `--legacy-peer-deps` for npm compatibility.

**Files changed:**
- `scripts/install.sh`
- `scripts/build.sh`
- `scripts/lint.sh`

```diff
#!/bin/bash

+ # Get the directory where this script is located
+ SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
+ ROOT_DIR="$(dirname "$SCRIPT_DIR")"

- cd api-gateway && npm i && cd -
+ cd "$ROOT_DIR/api-gateway" && npm i --legacy-peer-deps && cd -
```

---

## 10. Dependency Injection Fix

### Problem
`OrganizationController` used string-based injection `@Inject('QueryUtils')` which didn't match the module's class-based provider export.

### Solution
Removed string token injection, using class-based injection.

**File changed:** `api-gateway/src/organizations/organizations.controller.ts`

```diff
- import { Controller, Get, Post, Delete, Query, Body, Param, Inject, OnModuleInit, NotFoundException, Header } from '@nestjs/common'
+ import { Controller, Get, Post, Delete, Query, Body, Param, OnModuleInit, NotFoundException, Header } from '@nestjs/common'

@Controller('orgs')
export class OrganizationController implements OnModuleInit {
-   constructor(@Inject('QueryUtils') private readonly queryUtils: QueryUtils, private readonly logger: PinoLogger) {
+   constructor(private readonly queryUtils: QueryUtils, private readonly logger: PinoLogger) {
```

---

## Summary of Package Version Changes

| Package | Original | Updated |
|---------|----------|---------|
| `@nestjs/common` | ^6.10.14 / ^7.6.18 | ^8.4.7 |
| `@nestjs/core` | ^6.10.14 / ^7.6.18 | ^8.4.7 |
| `@nestjs/microservices` | ^6.10.14 / ^7.6.18 | ^8.4.7 |
| `@nestjs/config` | ^0.6.3 | ^1.2.1 |
| `@nestjs/cli` | ^6.13.2 / ^7.6.0 | ^8.2.8 |
| `@nestjs/testing` | ^6.10.14 / ^7.6.18 | ^8.4.7 |
| `grpc` | ^1.24.0 | Removed |
| `@grpc/grpc-js` | - | ^1.9.0 |
| `@grpc/proto-loader` | - | ^0.7.0 |
| `nestjs-pino` | ^1.4.0 | ^2.6.0 |
| `pino` | ^6.14.0 | ^7.11.0 |
| `pino-http` | - | ^6.6.0 |
| `rxjs` | ^6.6.7 | ^7.5.5 |
| `typescript` | 3.7.5 | 4.9.5 |

---

## How to Build and Run

```bash
# Install dependencies
./scripts/install.sh

# Build TypeScript
./scripts/build.sh

# Run with Docker
DOCKER_BUILDKIT=0 docker-compose build --no-cache
DOCKER_BUILDKIT=0 docker-compose up
```

## API Endpoints

- Health check: http://localhost:3000/healthz
- Organizations: http://localhost:3000/orgs
- Users: http://localhost:3000/users
- Swagger UI: http://localhost:8080
