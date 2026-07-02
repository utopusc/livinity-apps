# livinity-apps — Livinity Store catalog manifests

Source-of-truth manifests for Livinity Store catalog entries, consumable by the
`livinity-store-mcp` `store_sync_catalog` tool (expects `apps/<slug>/manifest.json`
on `main`; note: sync makes 1 GitHub API call per app — configure `GITHUB_TOKEN`
on the MCP server before paginating large syncs).

## Import wave 1 (2026-07-02)

131 apps converted from two Apache-2.0 sources:

| Source | Pin | Converted |
|---|---|---|
| [coollabsio/coolify](https://github.com/coollabsio/coolify) `templates/service-templates.json` | `e7dff30` | 103 |
| [caprover/one-click-apps](https://github.com/caprover/one-click-apps) `public/v4/apps` | `bd357c9` | 28 |

Conversion pipeline (`store-import` scripts in the livinity-io repo):
- one-click rule enforced: no required env prompts; secrets resolved to
  deterministic per-app literals (sha256(slug:var)); `manifest.env: []`
- host ports: unique per app from the reserved **42000+** band (existing catalog
  uses 41000-41534); only the MAIN service publishes a port; sidecar host ports
  stripped; inter-service traffic via compose service names
- CapRover `srv-captain--X` hostnames → compose service names; `$$cap_*`
  variables resolved from template defaults; apps with `dockerfileLines`,
  no-default required vars, or platform-magic requirements skipped
- Coolify `SERVICE_PASSWORD/USER/BASE64/HEX_*` magic vars resolved; apps whose
  compose bakes `SERVICE_FQDN/URL_*` (public URL needed at boot) deferred;
  file-`content` mounts and host binds skipped
- every compose passed `docker compose config` (132/132 green at generation)
- all published `verified=false` pending on-box smoke tests

## Rollback

Every imported row carries `manifest->>'importSource'` (`coolify@e7dff30` /
`caprover@bd357c9`). To remove the entire wave from the catalog:

```sql
DELETE FROM apps
WHERE manifest->>'importSource' IN ('coolify@e7dff30', 'caprover@bd357c9')
  AND verified = false;
```

(`verified=false` guard: any app an operator has since smoke-tested + verified is
kept unless you clear the flag first.) Then `git revert` the import commit here.
The import NEVER updates pre-existing rows (`ON CONFLICT (slug) DO NOTHING`), so
no restore of prior data is ever needed.
