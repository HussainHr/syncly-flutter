## Friends module (Firestore schema)

### Collections

#### `friend_requests/{requestId}`
- `requestId`: `${fromUid}_${toUid}`
- Fields:
  - `fromUid` (string)
  - `toUid` (string)
  - `status` (string): `pending` | `accepted` | `rejected` | `cancelled`
  - `createdAt` (timestamp)
  - `updatedAt` (timestamp)

#### `friendships/{friendshipId}`
- `friendshipId`: sorted `${minUid}_${maxUid}`
- Fields:
  - `users` (array<string>): `[uidA, uidB]`
  - `createdAt` (timestamp)

#### `users/{uid}/blocked/{blockedUid}`
- Document id is `blockedUid`
- Fields:
  - `blockedUid` (string)
  - `createdAt` (timestamp)

### Query patterns
- Incoming requests: `friend_requests where toUid == me and status == pending`
- Outgoing requests: `friend_requests where fromUid == me and status == pending`
- Friends: `friendships where users array-contains me`
- Blocked list: `users/{me}/blocked/*`

