# NearRide API

Express/MariaDB REST API for a nearby vehicle and driver listing marketplace. It does not book rides, calculate fares, track vehicles, or process payments.

## Setup

1. Copy `.env.example` to `.env` and replace every secret. `REGISTRATION_ENCRYPTION_KEY` must be kept stable or encrypted registration values become unreadable.
2. Create the configured MariaDB user and grant it access. Run `npm install`, then `npm run db:migrate`.
3. Start with `npm run dev`. Check `GET /health`.

All endpoints use `/api/v1`. Public discovery: `GET /categories`, `GET /listings/nearby`, `GET /listings/search`, `GET /listings/:publicId`. Authentication, provider CRUD, favourites, reports and contact-event routes follow the supplied specification. Responses never include listing coordinates or full registration numbers.

## Deployment on Ekafy

Use Node 20+ with `src/server.js` as the entrypoint, set the environment values in the managed dashboard, make `public/uploads` persistent and writable, and proxy HTTPS traffic to `PORT`. Run the schema once with a privileged deployment job, not on every boot. Set `NODE_ENV=production`, narrow `CORS_ORIGINS`, enable daily database backups, and terminate TLS at the platform proxy.

## Production notes

Use object storage for horizontally scaled uploads, add a scheduled expiry job, and place admin moderation behind a separately audited admin client. Google authentication returns `GOOGLE_AUTH_NOT_CONFIGURED` until `GOOGLE_CLIENT_ID` is set.
