# Compatibility fork

- Base: upstream v5.3.4, commit `6656c9d332735ca6a27725e0fb45a1715c4372d9`.
- Maintain compatibility and security. Do not merge upstream v6 or add Core, license checks, telemetry, auto-installers, or upstream binary downloads.
- Preserve upstream licensing and attribution.
- The LSP is in-process Lua. Build the bundled grammar locally; never load a shared cached parser in its place.
- Build JavaScript helpers from the checked-in TypeScript with Bun. They use only Node built-ins; do not restore the old npm toolchain.
- External kulala-fmt and its converter are intentionally excluded. Keep the Lua formatter.
- Build: `nvim --headless -u NONE -l scripts/build.lua`.
- Tests: `nvim --headless -u NONE -l tests/compat.lua` and `bun test tests/security.test.ts`.
- Review shell/process execution, network destinations, file writes, and all new dependencies. HTTP files and their scripts are trusted executable input, not a sandbox.
- Never disable Git commit signing.
