# Parallel Fetching and Waterfall Elimination

Patterns for eliminating sequential fetches — the #1 React data fetching performance problem — by parallelizing independent work and restructuring component trees.

## 1. Parallelize Independent Fetches with `Promise.all`

**Impact: CRITICAL** — Eliminates sequential waterfalls for 2-10x improvement.

When multiple fetches have no dependencies on each other, run them concurrently.

**Avoid — sequential (3 round trips):**

```typescript
async function loadDashboard() {
  const user = await fetchUser()
  const posts = await fetchPosts()
  const notifications = await fetchNotifications()
  return { user, posts, notifications }
}
```

**Prefer — parallel (1 round trip):**

```typescript
async function loadDashboard() {
  const [user, posts, notifications] = await Promise.all([
    fetchUser(),
    fetchPosts(),
    fetchNotifications(),
  ])
  return { user, posts, notifications }
}
```

When fetches have partial dependencies (B depends on A, but C doesn't), start independent work immediately:

```typescript
async function loadPage() {
  const userPromise = fetchUser()
  const configPromise = fetchConfig()

  const user = await userPromise
  const [config, posts] = await Promise.all([
    configPromise,
    fetchPosts(user.id), // depends on user
  ])
  return { user, config, posts }
}
```

---

## 2. Defer Await Until the Value Is Needed

**Impact: HIGH** — Starts work earlier without blocking on results you don't need yet.

A common mistake is to `await` each promise immediately, even when subsequent code doesn't need the result right away. Start the promise early, then `await` it at the point where you actually read the value.

**Avoid — blocks unnecessarily:**

```typescript
async function loadProfile(userId: string) {
  const user = await fetchUser(userId)       // waits here
  const prefs = await fetchPreferences()     // starts only after user resolves
  const avatar = buildAvatarUrl(user.avatar)
  return { user, prefs, avatar }
}
```

**Prefer — start early, await late:**

```typescript
async function loadProfile(userId: string) {
  const userPromise = fetchUser(userId)      // starts immediately
  const prefsPromise = fetchPreferences()    // starts immediately

  const user = await userPromise             // await when needed
  const avatar = buildAvatarUrl(user.avatar)
  const prefs = await prefsPromise           // may already be resolved

  return { user, prefs, avatar }
}
```

This is complementary to `Promise.all` — use defer-await when you need intermediate results between fetches, and `Promise.all` when you can wait for everything at once.

---

## 3. Avoid Fetch Waterfalls in Component Trees

**Impact: CRITICAL** — Parent-then-child fetching is the #1 performance problem.

When a parent fetches data and a child fetches its own data based on the parent's result, you create a waterfall. Restructure to fetch in parallel.

**Avoid — child can't start until parent finishes:**

```tsx
function UserPage({ userId }: { userId: string }) {
  const { data: user } = useQuery({
    queryKey: ['user', userId],
    queryFn: () => fetchUser(userId),
  })

  if (!user) return <Skeleton />
  return <UserPosts userId={user.id} /> // starts fetching only after user loads
}

function UserPosts({ userId }: { userId: string }) {
  const { data: posts } = useQuery({
    queryKey: ['posts', userId],
    queryFn: () => fetchPosts(userId),
  })
  // ...
}
```

**Prefer — fetch both at the same level:**

```tsx
function UserPage({ userId }: { userId: string }) {
  const { data: user } = useQuery({
    queryKey: ['user', userId],
    queryFn: () => fetchUser(userId),
  })
  const { data: posts } = useQuery({
    queryKey: ['posts', userId],
    queryFn: () => fetchPosts(userId),
  })

  if (!user) return <Skeleton />
  return (
    <div>
      <UserHeader user={user} />
      <PostList posts={posts ?? []} />
    </div>
  )
}
```

Or use a route-level loader to fetch all data before the component renders.
