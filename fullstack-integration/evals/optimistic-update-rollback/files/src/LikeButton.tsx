import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { getPost, setLiked, Post } from "./api";

export function LikeButton({ postId }: { postId: string }) {
  const qc = useQueryClient();
  const { data } = useQuery({ queryKey: ["post", postId], queryFn: () => getPost(postId) });
  const mutation = useMutation({
    mutationFn: (liked: boolean) => setLiked(postId, liked),
    onMutate: (liked) => {
      qc.setQueryData<Post>(["post", postId], (p) => p && { ...p, liked, likes: p.likes + (liked ? 1 : -1) });
    },
  });
  if (!data) return null;
  return (
    <button aria-pressed={data.liked} onClick={() => mutation.mutate(!data.liked)}>
      {data.liked ? "Liked" : "Like"} ({data.likes})
    </button>
  );
}
