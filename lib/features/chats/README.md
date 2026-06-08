## Chat core (Firestore schema)

### `chats/{chatId}`
Direct 1:1 chats.

- `type`: `direct`
- `members`: array<string> (2 uids)
- `createdAt`: timestamp
- `updatedAt`: timestamp
- `lastMessage`: map
  - `id` (string)
  - `senderUid` (string)
  - `text` (string)
  - `createdAt` (timestamp)
- `unread`: map<string,int> (per-user unread count)

`chatId` for direct chat: sorted `${minUid}_${maxUid}`.

### `chats/{chatId}/messages/{messageId}`
- `senderUid`: string
- `text`: string
- `type`: `text` (future: image/file)
- `createdAt`: timestamp
- `deliveredTo`: array<string> (uids)
- `readBy`: array<string> (uids)

### Typing indicator
`chats/{chatId}/typing/{uid}`
- `isTyping`: bool
- `updatedAt`: timestamp

Query:
- inbox: `chats where members array-contains myUid` (sort by `updatedAt desc`) (needs index)
- messages: `orderBy createdAt desc/asc`

