## Workspaces module (Firestore schema)

### `workspaces/{workspaceId}`
- `name` (string)
- `inviteCode` (string, unique, 8 chars)
- `createdBy` (uid)
- `memberUids` (array<string>)
- `memberCount` (number)
- `createdAt`, `updatedAt` (timestamp)

### `workspaces/{workspaceId}/members/{uid}`
- `uid` (string)
- `displayName` (string)
- `role` (string): `owner` | `member`
- `joinedAt` (timestamp)

### `workspaces/{workspaceId}/channels/{channelId}`
- `name` (string, e.g. `general`)
- `type` (string): `text`
- `createdBy` (uid)
- `lastMessage` (map, optional)
- `unread` (map<uid, int>)
- `createdAt`, `updatedAt` (timestamp)

### `workspaces/{workspaceId}/channels/{channelId}/messages/{messageId}`
- `senderUid`, `type` (`text`|`image`), `text`
- `mediaBase64` (optional, image)
- `createdAt`, `deliveredTo[]`, `readBy[]`

### `workspaces/{workspaceId}/channels/{channelId}/typing/{uid}`
- `isTyping` (bool), `updatedAt` (timestamp)

### Query patterns
- My workspaces: `workspaces where memberUids array-contains myUid`
- Join by code: `workspaces where inviteCode == CODE limit 1`
- Channels: subcollection under workspace (sorted locally by activity)
