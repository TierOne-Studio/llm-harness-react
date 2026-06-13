# TanStack Query and Optimistic Mutations

Replacing raw `useEffect` + `fetch` with a proper data layer: TanStack Query (or SWR) for caching/deduplication, and optimistic updates for instant mutation feedback.

## 1. Use TanStack Query for Client-Side Data

**Impact: CRITICAL** — Automatic caching, deduplication, revalidation, and error handling.

Raw `useEffect` + `fetch` lacks caching, deduplication, retry, and background refresh. Use a data fetching library.

**Avoid — no caching, no dedup, no error handling:**

```tsx
function UserProfile({ userId }: { userId: string }) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    setLoading(true)
    fetch(`/api/users/${userId}`)
      .then(r => r.json())
      .then(setUser)
      .finally(() => setLoading(false))
  }, [userId])

  if (loading) return <Skeleton />
  return <div>{user?.name}</div>
}
```

**Prefer — TanStack Query (recommended for Vite + React apps):**

```tsx
import { useQuery } from '@tanstack/react-query'

function UserProfile({ userId }: { userId: string }) {
  const { data: user, isLoading } = useQuery({
    queryKey: ['user', userId],
    queryFn: () => fetch(`/api/users/${userId}`).then(r => r.json()),
  })

  if (isLoading) return <Skeleton />
  return <div>{user?.name}</div>
}
```

TanStack Query is the strongest choice for Vite apps — it's framework-agnostic, has built-in `useSuspenseQuery`, devtools, infinite queries, optimistic mutations, and offline support. SWR is a lighter alternative that covers the basics (dedup, caching, revalidation) but has fewer features for complex mutation workflows.

Both give you: request deduplication, stale-while-revalidate caching, automatic retries, and background refresh.

**Setup for Vite apps:**

```tsx
// main.tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 60_000, // 1 minute
      retry: 2,
    },
  },
})

createRoot(document.getElementById('root')!).render(
  <QueryClientProvider client={queryClient}>
    <App />
  </QueryClientProvider>
)
```

---

## 2. Implement Optimistic Updates for Instant Feedback

**Impact: HIGH** — UI responds immediately without waiting for the server.

For mutations where the outcome is predictable (toggling a like, updating a name), update the UI instantly and reconcile with the server response.

**With TanStack Query:**

```tsx
import { useMutation, useQueryClient } from '@tanstack/react-query'

function LikeButton({ postId }: { postId: string }) {
  const queryClient = useQueryClient()

  const { mutate: toggleLike } = useMutation({
    mutationFn: () => fetch(`/api/posts/${postId}/like`, { method: 'POST' }),
    onMutate: async () => {
      await queryClient.cancelQueries({ queryKey: ['post', postId] })
      const previous = queryClient.getQueryData<Post>(['post', postId])
      queryClient.setQueryData<Post>(['post', postId], old => ({
        ...old!,
        liked: !old!.liked,
        likeCount: old!.liked ? old!.likeCount - 1 : old!.likeCount + 1,
      }))
      return { previous }
    },
    onError: (_err, _vars, context) => {
      queryClient.setQueryData(['post', postId], context?.previous)
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ['post', postId] })
    },
  })

  return <button onClick={() => toggleLike()}>Like</button>
}
```
