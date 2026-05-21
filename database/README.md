# Database

## Init Cloudflare D1

```bash
wrangler d1 execute deutsche-verb-db --local --file=database/schema.sql
wrangler d1 execute deutsche-verb-db --remote --file=database/schema.sql
```

## CSV format

Use UTF-8 CSV with these headers:

```csv
infinitive,translation,type,past_participle,preterite,auxiliary_verb,level,example_sentence,example_translation
```

Allowed values:

- `type`: `regular`, `irregular`
- `auxiliary_verb`: `haben`, `sein`
- `level`: `A1`, `A2`, `B1`, `B2`

See `database/verbs_template.csv`.

## Import

Cloudflare D1 imports SQL reliably through Wrangler. Keep the source content in CSV, convert rows into `INSERT OR IGNORE` statements, then execute the generated SQL:

```bash
wrangler d1 execute deutsche-verb-db --local --file=database/import_verbs.sql
wrangler d1 execute deutsche-verb-db --remote --file=database/import_verbs.sql
```

The import query uses `INSERT OR IGNORE`, so repeated imports do not duplicate verbs with the same `infinitive`.
