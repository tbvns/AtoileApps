#!/bin/bash
# =============================================================================
# Jellyfin Delete Account Script
# Removes a Jellyfin user and all associated rows.
#
# ENV VARS (required):
#   username    — the username to delete
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

python3 - <<PYEOF
import os, sqlite3, sys

db_path  = os.environ["DB_PATH"]
username = os.environ["username"]

con = sqlite3.connect(db_path)
cur = con.cursor()

cur.execute("SELECT Id FROM Users WHERE Username = ?", (username,))
row = cur.fetchone()
if row is None:
    print(f"[ERROR] User '{username}' not found.")
    con.close()
    sys.exit(1)

user_id = row[0]

# Delete all rows that reference this user, then the user itself
cur.execute("DELETE FROM Permissions  WHERE UserId = ?", (user_id,))
cur.execute("DELETE FROM Preferences  WHERE UserId = ?", (user_id,))
cur.execute("DELETE FROM AccessSchedules WHERE UserId = ?", (user_id,))
cur.execute("DELETE FROM Users        WHERE Id      = ?", (user_id,))

con.commit()
con.close()
print(f"[delete_account] Deleted user '{username}' (ID: {user_id})")
PYEOF
