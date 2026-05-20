# Deutsche Verb

Mobile app and API for learning German verbs with JWT auth, Cloudflare D1 sync, CSV-based content import, and offline-first Flutter caching.

## Structure

```text
database/
  schema.sql
  verbs_template.csv
  import_verbs.sql
backend/
  src/index.ts
  wrangler.toml
client/
  lib/
    core/
    data/
    providers/
    repositories/
    ui/
```

## Backend quick start

```bash
cd backend
pnpm install
wrangler d1 create deutsche-verb-db
wrangler d1 execute deutsche-verb-db --local --file=../database/sql/schema.sql
wrangler d1 execute deutsche-verb-db --local --file=../database/sql/import_verbs.sql
wrangler secret put JWT_SECRET
pnpm run dev
```

## Flutter quick start

```bash
cd client
setx PUB_CACHE "D:\FlutterSDK\.pub-cache"
set PUB_CACHE
# restart terminal
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8787
```
