export type Post = { id: string; liked: boolean; likes: number };
export async function getPost(id: string): Promise<Post> {
  const r = await fetch(`/api/posts/${id}`);
  if (!r.ok) throw new Error(`HTTP ${r.status}`);
  return r.json();
}
export async function setLiked(id: string, liked: boolean): Promise<Post> {
  const r = await fetch(`/api/posts/${id}/like`, { method: "PUT", body: JSON.stringify({ liked }), headers: { "Content-Type": "application/json" } });
  if (!r.ok) throw new Error(`HTTP ${r.status}`);
  return r.json();
}
