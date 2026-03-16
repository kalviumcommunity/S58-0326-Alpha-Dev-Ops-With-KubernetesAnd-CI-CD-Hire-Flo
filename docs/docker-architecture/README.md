# Docker Architecture Documentation — HireFlow Team 02

This folder documents Docker architecture concepts for the HireFlow
recruitment platform (Sprint #3, Assignment 4.13).

## Files

| File | Contents |
|------|---------|
| `docker-architecture-concepts.md` | Docker platform components, images, layers, containers, lifecycle |
| `layer-caching-guide.md` | Layer caching rules, optimal order, cache scenarios for HireFlow |
| `image-container-lifecycle.md` | Build vs run time, rolling update lifecycle, crash recovery |

## Key Concepts Covered

- Docker is a platform: CLI → Daemon → Runtime
- Images are immutable read-only layer stacks
- Layers are cached — order determines build speed
- Containers are image instances with a temporary writable layer
- Writable layer is discarded on container stop (use Volumes for persistence)
- Rolling updates work because old images remain intact during transition

## How This Applies to HireFlow

| Docker Concept | HireFlow Application |
|---------------|---------------------|
| Immutable images | Form version locked per image tag (sha-a3f91b2 = v2.4.1 always) |
| Layer caching | Fast CI builds — source changes rebuild in seconds not minutes |
| Shared image layers | 7 pods share one copy of node_modules in memory |
| Temporary writable layer | Logs sent to Loki, not stored inside containers |
| Rolling updates | Zero downtime during form version updates |