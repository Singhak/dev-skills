export function ProfileCard({ user }) {
  return (
    <article aria-label="Profile">
      <h2>{user.displayName}</h2>
      <p>{user.bioHtml}</p>
    </article>
  );
}
