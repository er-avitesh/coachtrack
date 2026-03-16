# CoachTrack - System Architecture

## Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter Mobile App                    │
│              (iOS + Android, single codebase)           │
└─────────────────────┬───────────────────────────────────┘
                      │ HTTPS / REST API
┌─────────────────────▼───────────────────────────────────┐
│                  Node.js + Express API                   │
│                    (Railway / Render)                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐             │
│  │   Auth   │  │ Coaching │  │ Tracking │             │
│  │ (JWT)    │  │ (Diet/   │  │ (Daily   │             │
│  │          │  │ Workout) │  │ Metrics) │             │
│  └──────────┘  └──────────┘  └──────────┘             │
└──────────┬──────────────────────────┬───────────────────┘
           │                          │
┌──────────▼──────────┐    ┌──────────▼──────────────────┐
│    PostgreSQL        │    │       AWS S3                │
│    (Supabase Free)  │    │   (Photo Storage)            │
│                     │    │                              │
└─────────────────────┘    └──────────────────────────────┘
```

## Tech Stack

| Layer      | Technology          | Reason                        |
|------------|---------------------|-------------------------------|
| Mobile     | Flutter             | Single iOS + Android codebase |
| Backend    | Node.js + Express   | Fast, simple REST API         |
| Database   | PostgreSQL          | Relational, reliable          |
| Auth       | JWT                 | Stateless, simple             |
| Storage    | AWS S3              | Cheap photo storage           |
| Hosting    | Railway.app         | Simple deploy, free tier      |
| DB Hosting | Supabase            | Free PostgreSQL tier          |

## Key Design Decisions

1. **JWT Auth** - Stateless tokens, role encoded (coach/participant)
2. **REST API** - Simple CRUD, no GraphQL overhead for MVP
3. **Single DB** - One PostgreSQL schema, simple joins
4. **S3 Presigned URLs** - App uploads directly to S3, no backend buffering
5. **Flat folder structure** - Easy to navigate, not over-engineered
