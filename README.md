# NearRide API

Express/MariaDB REST API for a nearby vehicle and driver listing marketplace. It does not book rides, calculate fares, track vehicles, or process payments.

## Setup

1. Copy `.env.example` to `.env` and replace every secret. `REGISTRATION_ENCRYPTION_KEY` must be kept stable or encrypted registration values become unreadable.
2. Create the configured MariaDB user and grant it access. Run `npm install`, then `npm run db:migrate`.
3. Start with `npm run dev`. Check `GET /health`.

## Google authentication

Set `GOOGLE_CLIENT_ID` in the API `.env` to the Google Cloud **Web OAuth
client ID**. Build or run Flutter with the same public client ID:

```sh
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=your-id.apps.googleusercontent.com
```

For Android, also create an Android OAuth client in Google Cloud for package
`com.ekafy.nearride` and add the SHA-1 fingerprints for every signing key used
(debug and release). The Web client ID remains the value passed to the API and
Flutter `GOOGLE_SERVER_CLIENT_ID`.

All endpoints use `/api/v1`. Public discovery: `GET /categories`, `GET /listings/nearby`, `GET /listings/search`, `GET /listings/:publicId`. Authentication, provider CRUD, favourites, reports and contact-event routes follow the supplied specification. Responses never include listing coordinates or full registration numbers.

## Deployment on Ekafy

Use Node 20+ with `src/server.js` as the entrypoint, set the environment values in the managed dashboard, make `public/uploads` persistent and writable, and proxy HTTPS traffic to `PORT`. Run the schema once with a privileged deployment job, not on every boot. Set `NODE_ENV=production`, narrow `CORS_ORIGINS`, enable daily database backups, and terminate TLS at the platform proxy.

## Production notes

Use object storage for horizontally scaled uploads, add a scheduled expiry job, and place admin moderation behind a separately audited admin client. Google authentication returns `GOOGLE_AUTH_NOT_CONFIGURED` until `GOOGLE_CLIENT_ID` is set.
