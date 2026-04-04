# Events Reference

Events are scripts triggered by the app manager to control Jellyfin programmatically.  
All account passwords are garbage values — authentication is handled exclusively via tokens through the reverse proxy.

## Setup Events

Run once at install time to configure Jellyfin so it integrates cleanly into the ecosystem without any manual setup by the user.

### `setup`
Performs the initial server configuration: disables public signup, sets the server name, configures the base URL, and applies any default library or transcoding settings. After this runs, the server is ready to use with no manual steps required.

---

## Account Management Events

### `create_account`
Creates a new Jellyfin user with a ---randomly generated garbage password. The account is not usable via password login by design — access is only possible through a valid token. Returns the internal Jellyfin user ID.

| Arg | Type | Required |
|---|---|---|
| `username` | string | ✅ |

### `delete_account`
Permanently deletes a user and all their data (watch history, preferences, etc.). Should be preceded by `revoke_all_tokens` to cleanly invalidate any active sessions before removal.

| Arg | Type | Required |
|---|---|---|
| `username` | string | ✅ |

### `disable_account`
Locks a user account without deleting it. The user's data is preserved but all their tokens stop working immediately. Useful for temporary suspension.

| Arg | Type | Required |
|---|---|---|
| `username` | string | ✅ |

### `enable_account`
Re-enables a previously disabled account. Does not restore old tokens — a new token must be generated separately via `generate_token`.

| Arg | Type | Required |
|---|---|---|
| `username` | string | ✅ |

---

## Token Management Events

### `generate_token`
Creates a new API token for a user and returns it. The token is what the reverse proxy stores and injects into requests on behalf of the user. The generated token should be stored securely — it cannot be retrieved again after creation.

| Arg | Type | Required |
|---|---|---|
| `username` | string | ✅ |
| `label` | string | ❌ (defaults to `"managed"`) |

### `revoke_token`
Deletes a specific token. Use this when rotating or when a single token is suspected to be compromised.

| Arg | Type | Required |
|---|---|---|
| `username` | string | ✅ |
| `token` | secret | ✅ |

### `revoke_all_tokens`
Deletes every active token for a user in one operation. Use before `delete_account`, or when a user's access needs to be fully cut immediately.

| Arg | Type | Required |
|---|---|---|
| `username` | string | ✅ |

### `verify_token`
Checks whether a token is valid and returns the associated username. Used by the reverse proxy or the app manager to validate an existing token before trusting it.

| Arg | Type | Required |
|---|---|---|
| `token` | secret | ✅ |

### `rotate_token`
Atomically generates a new token and revokes the old one. This is the standard operation for periodic credential refresh — it ensures there is no window where the user has no valid token or two valid tokens at once.

| Arg | Type | Required |
|---|---|---|
| `username` | string | ✅ |
| `old_token` | secret | ✅ |
