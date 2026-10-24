# State, Caching and Mutation Patterns

## Query key factory (TanStack Query, React)
```ts
export const orderKeys = {
  all: ["orders"] as const,
  list: (f: OrderFilter) => [...orderKeys.all, "list", f] as const,
  detail: (id: string) => [...orderKeys.all, "detail", id] as const,
};
```

## Optimistic update with rollback
```ts
const qc = useQueryClient();
const rename = useMutation({
  mutationFn: (v: { id: string; name: string; version: number }) => api.renameOrder(v),
  onMutate: async (v) => {
    await qc.cancelQueries({ queryKey: orderKeys.detail(v.id) });
    const prev = qc.getQueryData<Order>(orderKeys.detail(v.id));
    qc.setQueryData<Order>(orderKeys.detail(v.id), (o) => o && { ...o, name: v.name });
    return { prev };
  },
  onError: (err, v, ctx) => {
    if (ctx?.prev) qc.setQueryData(orderKeys.detail(v.id), ctx.prev); // rollback
    showErrorFromProblem(err); // maps 409/422/5xx per error table
  },
  onSuccess: (saved) => qc.setQueryData(orderKeys.detail(saved.id), saved), // server truth
  onSettled: () => qc.invalidateQueries({ queryKey: orderKeys.all }),
});
```
Test it: component test where MSW returns 500 after a delay → assert the old name is restored and an alert is shown.

## SSR hydration (Next.js App Router pattern)
```tsx
// server component
const qc = new QueryClient();
await qc.prefetchQuery({ queryKey: orderKeys.list(f), queryFn: () => api.listOrders(f) });
return <HydrationBoundary state={dehydrate(qc)}><OrderList filter={f} /></HydrationBoundary>;
```
Rules: create a new QueryClient per request on the server (never a module-level singleton, which would leak data between users); format dates/currency identically on server and client (fixed locale/timezone or format on client only).

Equivalents: Nuxt `useAsyncData`/`useFetch` with key; SvelteKit `load`; Remix/React Router loaders + `useFetcher`; Angular SSR `TransferState`.

## Idempotent create
```ts
const key = useRef(crypto.randomUUID());
await api.createPayment(body, { headers: { "Idempotency-Key": key.current } });
// regenerate the key only after a confirmed success or when the user changes the form
```

## Optimistic concurrency
Server returns `version` (or `ETag`); client sends it back (`If-Match`); server responds 409/412 on mismatch; UI offers reload or merge.

## Logout hygiene
On logout: `queryClient.clear()`, clear app stores, remove non-HttpOnly storage keys, close sockets, and navigate with a full reload if the app holds sensitive in-memory state.
