# 🧩 Project Definition (WHAT WE ARE BUILDING)

This project is a:

👉 Social Blog / Community App

Users can:

• create an account (custom auth, no Supabase Auth)
• create posts (text + multiple images)
• view a feed of posts
• view user profiles
• comment on posts
• attach images to comments
• react to posts/comments (like, etc.)
• upload avatars
• edit/delete their own content

---

## Core Features

### Users

- register / login / logout
- profile with avatar, display name, bio

### Posts

- create post
- text content
- multiple images
- list feed (paginated)
- update/delete own posts

### Comments

- add comments
- optional images
- update/delete own comments

### Reactions

- like/react to posts or comments
- counts per item

---

## UI Expectations

- feed style layout
- avatars everywhere
- image-heavy content
- fast scrolling lists
- cached images
- shimmer loading
- pagination ready

All screens must follow the architecture defined in this document.

# Agents Architecture Guide

Supabase + Provider + ChangeNotifier + Repository Pattern

This document defines the complete app architecture, database structure,
and responsibilities of every layer.

This is the single source of truth for how features must be built.

If code violates this guide, it is considered incorrect.

---

# 🎯 Goals

We want:

• clean architecture  
• fast queries  
• scalable structure  
• easy testing  
• maintainable code  
• strict separation of layers  
• deep linking support  
• future-proof (pagination, realtime, caching)  
• FULL custom authentication  
• ZERO Supabase Auth usage  
• optimized image loading  
• zero layout jank during loading

---

# 🧠 High-Level Architecture

UI (Widgets)  
↓  
ChangeNotifiers (State)  
↓  
Repositories (Business Logic)  
↓  
Services (Supabase only)  
↓  
Supabase (Database + Storage)

⚠️ Supabase Auth is NEVER used.

---

# 🚨 HARD RULES

❌ Widgets MUST NOT call Supabase  
❌ Widgets MUST NOT import Services  
❌ Widgets MUST NOT contain business logic  
❌ Widgets MUST NOT upload files  
❌ Widgets MUST NOT use Map<String,dynamic>  
❌ Widgets MUST NOT use Image.network

✅ Widgets talk ONLY to Notifiers  
✅ Notifiers talk ONLY to Repositories  
✅ Repositories talk ONLY to Services  
✅ Services talk ONLY to Supabase  
✅ ALL network images MUST use CachedNetworkImage  
✅ ALL loading states MUST use Shimmer

If any layer skips the chain → architecture is broken.

---

# 📦 REQUIRED DEPENDENCIES (MANDATORY)

```yaml
dependencies:
  cached_network_image: ^3.x
  shimmer: ^3.x
```

---

# Supabase already contains these tables:

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

Row Level Security is disabled.
Do not generate SQL.
Use these tables as-is.
SQL Code to create tables in sql.txt
Inform user if it needs to update

---

# 🖼 IMAGE LOADING STANDARD (MANDATORY)

To ensure:

• disk caching  
• memory caching  
• smooth scrolling  
• zero flicker  
• graceful loading states  
• consistent UX

---

## ❌ NEVER

❌ Image.network  
❌ FadeInImage  
❌ manual loading spinners  
❌ custom skeleton loaders  
❌ loading logic inside notifiers

---

## ✅ ALWAYS

Use:

CachedNetworkImage + Shimmer

All remote images must:

• cache automatically  
• show shimmer placeholder  
• handle errors gracefully

---

# 🔹 REQUIRED WRAPPER WIDGET

Create ONE reusable widget:

lib/ui/common/widgets/app_image.dart

```dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class AppImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? radius;

  const AppImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, __) => const _ShimmerBox(),
        errorWidget: (_, __, ___) =>
            const Icon(Icons.broken_image, size: 24),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(color: Colors.white),
    );
  }
}
```

---

# 🚨 IMAGE RULES

### MUST

✅ use AppImage for:
• avatars  
• post images  
• comment images  
• any storage URL

✅ cache automatically  
✅ show shimmer

---

### MUST NOT

❌ Image.network  
❌ CachedNetworkImage directly in UI  
❌ custom placeholders per screen

All images MUST go through AppImage for consistency.

---

# 🔐 AUTHENTICATION (CUSTOM ONLY)

We DO NOT use Supabase Auth.

Authentication is fully handled using:

users_jeremiah table + password hashing

We implement:
• register  
• login  
• change password  
• logout  
• session cache

inside repositories.

---

# 🚨 AUTH RULES

### MUST

✅ store hashed passwords (bcrypt/argon2)  
✅ validate password in repository  
✅ cache session locally  
✅ treat users_jeremiah as the ONLY user source

### MUST NOT

❌ never use Supabase Auth  
❌ never store plaintext passwords  
❌ never validate password in UI

---

# 📁 Folder Structure

lib/
├─ models/  
├─ services/  
├─ repositories/  
├─ notifiers/  
├─ ui/  
│ ├─ common/  
│ │ └─ widgets/  
│ │ └─ app_image.dart  
└─ theme/

---

# Routing

Use Go_Router, handle auth gate/guard

---

# 🗄 DATABASE STRUCTURE

## users_jeremiah

id (uuid, PK)  
email (unique)  
password_hash  
display_name  
avatar_url  
bio  
created_at  
updated_at

⚠️ Handles BOTH auth + profile.

---

## posts_jeremiah

id  
author_id → users_jeremiah.id  
title  
content  
created_at  
updated_at

---

## posts_image

id  
post_id → posts_jeremiah.id  
url

---

## comments_jeremiah

id  
post_id → posts_jeremiah.id  
author_id → users_jeremiah.id  
content  
created_at  
updated_at

---

## comment_images_jeremiah

id  
comment_id → comments_jeremiah.id  
url

---

## reactions_jeremiah

id  
user_id  
post_id (nullable)  
comment_id (nullable)  
reaction_type  
created_at

---

# 🔴 CRITICAL FETCH RULE (VERY IMPORTANT)

## Posts and Comments MUST ALWAYS INCLUDE

### Author info

• display_name  
• avatar_url

### Images

• all related image URLs

---

# 🚨 NEVER DO THIS

❌ fetch posts  
❌ then fetch users  
❌ then fetch images (N+1 queries)

---

# ✅ ALWAYS DO THIS

### SINGLE JOIN QUERY

Posts must return:

PostModel(
id,
title,
content,
authorName,
authorAvatar,
images[]
)

Comments must return:

CommentModel(
id,
content,
authorName,
authorAvatar,
images[]
)

---

# 🔹 Services

Supabase only  
Stateless  
Raw queries only  
No business logic

---

# 🔹 Repositories

Business logic only  
Combine services  
Handle validation + storage orchestration

---

# 🔹 ChangeNotifiers

Hold:
• loading  
• lists  
• cache  
• errors

No business logic.

---

# 🔹 Data Flow Example

Create Post:

Widget  
→ PostNotifier  
→ PostRepository  
→ StorageService.uploadImages  
→ BlogService.createPost  
→ return post WITH author + images  
→ notifyListeners

---

# 🔹 Performance Rules

Always:
• joins  
• batch queries  
• Future.wait  
• caching

Never:
• N+1 queries  
• multiple fetches for author/images  
• storage calls in UI

---

# 🔹 FINAL SUMMARY

users_jeremiah → auth + profile  
Services → Supabase only  
Repositories → business logic  
Notifiers → state  
UI → presentation only

Images:
✔ Cached  
✔ Shimmer loading  
✔ Always via AppImage

Posts/comments MUST always include:
✔ author display_name  
✔ author avatar  
✔ images

No Supabase Auth.
Ever.
On app start --> check or wait if logged in or till logged in --> load data --> show home

Keep boundaries strict.
