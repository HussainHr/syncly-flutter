# Syncly — Demo Script

Step-by-step walkthrough for company submission. Use **two devices or emulators** (Host + Member).

## Prerequisites

- Both devices logged into Firebase project `syncly-flutter`
- Notification permission granted on Member device
- Internet connected initially

---

## Part 1 — Host setup (Device A)

1. **Register as Host**
   - Open app → Register
   - Enter name, email, password
   - Select role: **Host**
   - Tap Register → lands on Workspaces home

2. **Create workspace**
   - Tap **Create workspace**
   - Name: `Acme Team`
   - Tap Create → opens channel list with `#general`

3. **Copy invite code**
   - On channels screen, tap the key icon (or Copy on invite code bar)
   - Share code with Member (e.g. `AB12CD34`)

4. **Send a message**
   - Open `#general`
   - Type: `Welcome to Syncly!`
   - Send

---

## Part 2 — Member joins (Device B)

1. **Register as Member**
   - Register with different email
   - Select role: **Member**

2. **Join workspace**
   - Tap **Join workspace**
   - Enter invite code from Host
   - Tap Join → opens `#general`

3. **Reply in channel**
   - Open `#general`
   - Type: `Thanks, joined successfully!`
   - Send

---

## Part 3 — Notifications (Device A backgrounded)

1. On **Device A (Host)**, press Home to background the app (don't force-kill)

2. On **Device B (Member)**, send: `Can you see this notification?`

3. On **Device A**, expect a local notification: *"New channel message"*

4. **Tap notification** → app opens directly to `#general` channel

---

## Part 4 — Navigation & profile

1. From workspace channels, tap **back** → returns to Workspaces home

2. Tap **profile avatar** (top right) → My Profile

3. Open **Settings** from menu → toggle dark mode / notifications

4. Navigate back to workspace and verify messages persist

---

## Part 5 — Offline-lite (optional)

1. Open a channel with messages on either device

2. Enable **Airplane mode**

3. Verify:
   - Orange banner: *"Offline — showing cached data"*
   - Previously loaded messages still visible

4. Disable airplane mode → banner disappears, new messages sync

---

## Part 6 — Create channel (Host only)

1. On Device A, open workspace channels

2. Tap **New channel** → name: `announcements`

3. Send a message in `#announcements`

4. On Device B, verify new channel appears in list with unread badge

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Permission denied on create/join | Deploy rules: `firebase deploy --only firestore:rules --project syncly-flutter` |
| No notification on Host | Ensure notifications enabled in Settings; app must not be force-killed |
| Invalid invite code | Check code is uppercase, 6–8 chars |
| Back button missing | Hot restart app (navigation fix in Sprint 4) |

---

## Submission checklist

- [ ] Host creates workspace
- [ ] Member joins via invite code
- [ ] Realtime chat in `#general`
- [ ] Image send in channel (optional)
- [ ] Notification received when backgrounded
- [ ] Tap notification opens correct channel
- [ ] Back navigation to profile/settings works
- [ ] Offline banner + cached data visible
