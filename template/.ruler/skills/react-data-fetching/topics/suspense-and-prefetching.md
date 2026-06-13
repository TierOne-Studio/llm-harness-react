# Suspense Boundaries and Prefetching

Declarative loading states with Suspense, and starting fetches before navigation so users never see a spinner.

## 1. Use Suspense for Declarative Loading States

**Impact: HIGH** — Cleaner code, automatic loading coordination, streaming support.

Suspense lets you declare loading boundaries in the component tree instead of managing `isLoading` state in every component.

**Avoid — manual loading orchestration:**

```tsx
function Dashboard() {
  const { data: user, isLoading: userLoading } = useQuery(userQuery)
  const { data: stats, isLoading: statsLoading } = useQuery(statsQuery)

  if (userLoading || statsLoading) return <FullPageSpinner />
  return (
    <div>
      <UserHeader user={user} />
      <StatsPanel stats={stats} />
    </div>
  )
}
```

**Prefer — Suspense boundaries:**

```tsx
function Dashboard() {
  return (
    <Suspense fallback={<FullPageSpinner />}>
      <DashboardContent />
    </Suspense>
  )
}

function DashboardContent() {
  const { data: user } = useSuspenseQuery(userQuery)
  const { data: stats } = useSuspenseQuery(statsQuery)
  return (
    <div>
      <UserHeader user={user} />
      <StatsPanel stats={stats} />
    </div>
  )
}
```

For independent sections, use separate Suspense boundaries so they load independently:

```tsx
function Dashboard() {
  return (
    <div>
      <Suspense fallback={<HeaderSkeleton />}>
        <UserHeader />
      </Suspense>
      <Suspense fallback={<StatsSkeleton />}>
        <StatsPanel />
      </Suspense>
    </div>
  )
}
```

TanStack Query provides `useSuspenseQuery` and SWR provides `{ suspense: true }` option.

---

## 2. Prefetch Data Before Navigation

**Impact: HIGH** — Eliminates loading states on page transitions.

Start fetching data before the user commits to a navigation — on hover, focus, or route preload.

**With TanStack Query:**

```tsx
import { useQueryClient } from '@tanstack/react-query'

function ProjectLink({ projectId }: { projectId: string }) {
  const queryClient = useQueryClient()

  const prefetch = () => {
    queryClient.prefetchQuery({
      queryKey: ['project', projectId],
      queryFn: () => fetchProject(projectId),
      staleTime: 30_000,
    })
  }

  return (
    <Link
      to={`/projects/${projectId}`}
      onMouseEnter={prefetch}
      onFocus={prefetch}
    >
      View Project
    </Link>
  )
}
```

**With React Router loaders (Vite apps):**

```tsx
// routes.tsx
const routes = [
  {
    path: '/projects/:id',
    loader: ({ params }) => queryClient.ensureQueryData({
      queryKey: ['project', params.id],
      queryFn: () => fetchProject(params.id!),
    }),
    Component: ProjectPage,
  },
]
```
