# Security review: 2026-10-31

Base: upstream v5.3.4, `6656c9d332735ca6a27725e0fb45a1715c4372d9`.
This is a limited source review and hardening pass, not an independent audit or
proof that the code has no backdoors. No evidence of deliberate malicious
behavior was identified in the reviewed runtime paths.

## Changes

- No Core, license endpoint, upstream binary download, or external LSP executable.
- Regenerate parser C from the bundled `grammar.js` and compile it locally.
  Load only `.build/dkarter_kulala_http.so`, using a fork-specific language/symbol
  that cannot collide with an already-loaded upstream parser. Missing builds fail
  setup rather than falling back. Invalidate JS helpers before every rebuild.
- Build JavaScript helpers from checked-in TypeScript using Bun, with no npm
  dependencies, package installation, lifecycle scripts, or minification.
- Exclude the separate kulala-fmt submodule, executable, and import converter.
  Keep the Lua formatter and LSP. Old Rollup/npm scripting tooling is removed.
- Replace shell-based OpenSSL calls and response-file formatting with argument
  arrays and stdin. RSA temporary files are owner-only and cleaned up after use.
- Reject prototype traversal in JavaScript variable paths.
- Make diagnostics local-only. Do not collect request or configuration snapshots
  or submit issues with the user's authenticated GitHub CLI.
- Separate caches/state from upstream. Create cache directories with owner-only
  permissions. Do not inspect or migrate old request caches or credentials.
- Disable repository Actions until replacement workflows have been reviewed.

## Coverage

Manual review focused on runtime process execution, dynamic evaluation, network
destinations, file access, authentication helpers, build entrypoints, and the
TypeScript request helper sources. Bundled grammar source was reviewed and used
to regenerate C; checked-in generated C was not used for the local parser build.

Semgrep CE 1.183.0, `p/security-audit` plus four local generic Lua rules, with
metrics and version checks disabled: 141 rules ran on 126 files under `lua/`.
All six findings were reviewed: standard Go `unsafe` pointer interop in the unused
grammar Go binding; three documented shell-command branches; and two intentional
dynamic-code loaders (request Lua scripts and explicit CLI config). A Tree-sitter
C header macro was only partially parsed. This scan is **not** strong Lua coverage;
the generic rules and manual review cover Lua execution entrypoints separately.

The generic Lua scan intentionally identifies the unsandboxed Lua script runner,
the explicit CLI config loader, and the documented shell-command metadata feature.
Those are retained functionality, not evidence of a backdoor. It is an inventory,
not a complete taint analysis.

Regression checks cover parser loading after a working-directory change, the
in-process LSP and Lua formatting, JavaScript builds and variable persistence,
prototype traversal, PKCE, synthetic JWT signing, shell metacharacters in response
paths and HMAC keys, and HTTP POST against a loopback-only test server. Tests use
an empty environment and isolated HOME, not personal request files or credentials.
The historical Busted suite has not been run; its old bootstrap fetches remote code.

## Remaining trust and limitations

- `.http` files are executable input. Lua/JS scripts and `stdin-cmd` metadata have
  the user's permissions. Includes can read files; redirects can write files.
  Only run trusted collections. This fork is not a sandbox.
- Request, response, cookie, auth, and script state can contain plaintext secrets
  locally. Error text can also contain sensitive values. Redact before sharing.
- HMAC key material is passed as an OpenSSL argument, without a shell. Local
  process inspection may expose it. Child processes inherit the user's environment.
- cURL, OpenSSL, Node, Bun, tree-sitter-cli, the C compiler, and optional jq,
  grpcurl, websocat, or configured formatters remain external trusted tools.
  This review does not audit their implementations or rebuild the whole toolchain.
- Historical docs, development scripts, and workflows are preserved for context,
  not security-reviewed build instructions. Do not run upstream Docker images,
  floating bootstrap scripts, publishing workflows, or old npm manifests.
- Local validation was on macOS Apple Silicon with Neovim 0.12.6, Bun 1.4.4,
  Node 26.13.0, and tree-sitter-cli 0.27.1. Other OS/Neovim versions are unverified.

## Repeat the scans

Use an isolated HOME with no scanner login or credentials. Do not upload results
containing private request data.

```sh
semgrep scan --config p/security-audit --config scripts/security-rules.yml \
  --metrics=off --disable-version-check --disable-nosem lua
nvim --headless -u NONE -l scripts/build.lua
nvim --headless -u NONE -l tests/compat.lua
bun test tests/security.test.ts
```

The optional HTTP smoke check needs `KULALA_TEST_URL` pointing to a local JSON
echo server. Tests do not contact a public echo service.
