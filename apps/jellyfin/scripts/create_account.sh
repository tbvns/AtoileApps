#!/bin/bash
# =============================================================================
# Jellyfin Create Account Script
# Creates a single Jellyfin user with admin permissions.
#
# ENV VARS (required):
#   username    — the username to create
#   key         — the password/key for the user
#   DB_PATH     — path to jellyfin.db (default: /config/data/jellyfin.db)
# =============================================================================

export DB_PATH="${DB_PATH:-/config/data/jellyfin.db}"

set -euo pipefail

if [[ ! -f "$DB_PATH" ]]; then
  echo "[ERROR] Database not found at $DB_PATH — has Jellyfin started at least once?"
  exit 1
fi

if [[ -z "${username:-}" ]]; then
  echo "[ERROR] 'username' env var is not set or empty."
  exit 1
fi

if [[ -z "${key:-}" ]]; then
  echo "[ERROR] 'key' env var is not set or empty."
  exit 1
fi

python3 - <<PYEOF
import json, os, hashlib, binascii, secrets, uuid, sqlite3, sys
from datetime import datetime, timezone

db_path  = os.environ["DB_PATH"]
username = os.environ["username"]
key      = os.environ["key"]
now      = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S.0000000")

def pbkdf2_hash(key: str) -> str:
    iterations = 210000
    salt = secrets.token_bytes(32)
    dk   = hashlib.pbkdf2_hmac("sha512", key.encode(), salt, iterations)
    salt_hex = binascii.hexlify(salt).decode().upper()
    dk_hex   = binascii.hexlify(dk).decode().upper()
    return f"\$PBKDF2-SHA512\$iterations={iterations}\${salt_hex}\${dk_hex}"

con = sqlite3.connect(db_path)
cur = con.cursor()

cur.execute("SELECT COUNT(*) FROM Users WHERE Username = ?", (username,))
if cur.fetchone()[0] > 0:
    print(f"[ERROR] User '{username}' already exists.")
    con.close()
    sys.exit(1)

user_id       = str(uuid.uuid4()).upper()
password_hash = pbkdf2_hash(key)

cur.execute("SELECT COALESCE(MAX(InternalId), 0) + 1 FROM Users")
internal_id = cur.fetchone()[0]

cur.execute("""
    INSERT INTO Users (
        Id, Username, Password,
        AuthenticationProviderId, PasswordResetProviderId,
        MustUpdatePassword, InvalidLoginAttemptCount, LoginAttemptsBeforeLockout,
        MaxActiveSessions, EnableAutoLogin, EnableLocalPassword,
        EnableNextEpisodeAutoPlay, EnableUserPreferenceAccess,
        DisplayCollectionsView, DisplayMissingEpisodes, HidePlayedInLatest,
        RememberAudioSelections, RememberSubtitleSelections,
        PlayDefaultAudioTrack, SubtitleMode, SyncPlayAccess,
        InternalId, LastActivityDate, LastLoginDate, RowVersion
    ) VALUES (
        ?, ?, ?,
        'Jellyfin.Server.Implementations.Users.DefaultAuthenticationProvider',
        'Jellyfin.Server.Implementations.Users.DefaultPasswordResetProvider',
        0, 0, NULL, 0, 0, 0, 1, 1, 0, 0, 1, 1, 1, 1, 0, 0,
        ?, ?, ?, 1
    )
""", (user_id, username, password_hash, internal_id, now, now))

for kind in range(4):
    cur.execute(
        "INSERT INTO Preferences (Kind, UserId, Value, RowVersion) VALUES (?, ?, '', 0)",
        (kind, user_id)
    )

cur.execute(
    "INSERT OR IGNORE INTO Permissions (UserId, Kind, Value, RowVersion) VALUES (?, 0, 1, 0)",
    (user_id,)
)

con.commit()
con.close()
print(f"[create_account] Created user '{username}' (ID: {user_id})")
PYEOF
