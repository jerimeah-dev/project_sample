# Copilot Mandatory Architecture Rules

These rules are STRICT. Generated code must ALWAYS follow them.

---

## Architecture Chain (never skip)

UI (Widgets)
→ Notifiers (ChangeNotifier)
→ Repositories (business logic)
→ Services (Supabase only)
→ Supabase

---

## Forbidden

- Widgets calling Supabase
- Widgets importing services
- Business logic in UI
- Storage calls in UI
- Image.network
- FadeInImage
- Supabase Auth
- N+1 queries
- Multiple fetches for author/images
- Map<String,dynamic> in UI

---

## Required

- Provider + ChangeNotifier
- Repository pattern
- Services are stateless + raw queries only
- Repositories contain all business logic
- Join queries only (posts/comments must include author + images)
- CachedNetworkImage for ALL remote images
- Shimmer for ALL loading placeholders
- Always use AppImage wrapper widget

---

## Image Rule

NEVER use:
Image.network

ALWAYS use:
CachedNetworkImage

---

## Database

Use existing tables only:

users_jeremiah
posts_jeremiah
posts_image
comments_jeremiah
comment_images_jeremiah
reactions_jeremiah

Buckets:
avatars
post-images
comment-images

Do NOT generate SQL.
Do NOT modify schema.

---

## Auth

Custom auth only using users_jeremiah.

Never use Supabase Auth.
Passwords must be hashed.
Validation happens in repository only.

---

## Output Expectations

When generating code:

- Respect folder structure
- Follow clean separation of layers
- Keep UI dumb
- Keep services simple
- Put logic in repositories
- Optimize queries
- Include author + images in models
