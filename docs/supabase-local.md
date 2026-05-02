# Local Supabase Notes

If the Supabase CLI is not available in the shell, local migrations can be applied through the Docker Postgres container.

```bash
docker cp supabase/migrations/0012_production_flows.sql supabase_db_f1-fantasy-league:/tmp/0012_production_flows.sql
docker exec supabase_db_f1-fantasy-league psql -U postgres -d postgres -v ON_ERROR_STOP=1 -f /tmp/0012_production_flows.sql
docker exec supabase_db_f1-fantasy-league psql -U postgres -d postgres -c "notify pgrst, 'reload schema';"
```

Prefer the Supabase CLI when it is installed:

```bash
supabase migration list
supabase db reset
```

When an app error says an RPC is missing from the schema cache, first check that the migration was applied, then reload PostgREST schema cache.
