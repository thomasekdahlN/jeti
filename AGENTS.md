# AGENTS.md

## Project entrypoints

- `ecu.lua` is the active script for Jeti transmitters with more memory.
- `ecu_16.lua` is the active script for older Jeti transmitters with less memory.
- Prefer the root entrypoints above when making changes.
- Treat `ecu/lib/ecu.lua` and `ecu/lib/ecu_16.lua` as stale unless explicitly told otherwise.

## Documentation

- Always consult the Jeti Lua documentation under `docs/` before making Jeti API changes.
- The main local Jeti Lua documentation in this repository is `docs/JETIDCDS_Lua_API_1.5.pdf` or online here https://jetiforum.de/media/kunena/attachments/191/JETIDCDS_Lua_API_1.5.pdf.
- Jeti website: http://jetimodel.com/
- The Jeti Lua documentation references the Lua 5.3 manual and excludes compatibility with older Lua 5.2 and 5.1 builds.
- Only use Lua 5.3 syntax and language behavior in this repository.
- Do not introduce Lua 5.1/5.2 compatibility patterns or Lua 5.4+ syntax/features.

## Memory and safety requirements

- Memory usage is critical for this project.
- Both scripts and all libraries must use as little memory as possible.
- Avoid unnecessary allocations, duplicated state, and repeated table creation in hot paths.
- Prefer simple, predictable code over abstraction-heavy solutions.
- All code must be safe against memory leaks and long-running runtime degradation.
- Treat this as critical ECU dashboard functionality for turbines, so stability and fail-safe behavior have priority over new features.

## Change guidance for AI agents

- Keep both active entrypoints stable and aligned where appropriate, while respecting the lower-memory constraints of `ecu_16.lua`.
- Before changing Jeti-facing behavior, verify the API usage against the documentation in `docs/`.
- Prefer targeted, conservative fixes.
- Do not assume higher-memory devices and lower-memory devices can share identical implementations.
- Any commit must use the Conventional Commits format.
- Do not create commits or push changes unless the user has explicitly approved it.