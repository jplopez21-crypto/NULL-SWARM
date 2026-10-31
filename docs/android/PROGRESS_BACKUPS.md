# Portable progression backups

From the command menu, choose **PROGRESS BACKUP**, then **EXPORT MY PROGRESS**. The code appears in the field and is copied to the clipboard. Paste it into a safe note outside the game; the clipboard alone is not long-term storage.

In another build that supports this feature, open **PROGRESS BACKUP**, choose **PASTE CODE**, then **PREVIEW RESTORE**. Review current/backup salvage and deployment counts. **RESTORE THIS BACKUP** replaces progression and settings; it does not add the two balances together. Cancel leaves everything unchanged.

Each successful restore preserves the pre-import save locally. **PREVIEW PREVIOUS SAVE** opens the same confirmation flow to recover it. This is one recovery level, not a full backup history; keep independent exported codes.

Codes include salvage, earned kit requirements, research, completed-run statistics and settings. Current-run equipment/corruption and reward ledgers are excluded. Backups are versioned, size-limited and checksummed to detect accidental damage. They are not encrypted or cryptographically authenticated, and never grant billing entitlements. Invalid codes are rejected before replacing data. File-write failure leaves in-memory progress unchanged.

This does not extract data from other apps. An older installed APK without an export screen cannot export its private save through this feature. Keep that working install; uninstalling deletes private app data. The Preview signing setup remains separate and still requires owner environment secrets.

Automation covers codec/schema failures, persistence/recovery, GUI preview/cancel/restore, four display sizes, and real Android clipboard export/paste, confirmed restore and APK-update retention. Physical cross-app manual transfers remain untested until compatible builds can be installed on a phone.
