# Kulala v5 compatibility fork

This is Dorian Karter's source fork of **v5.3.4** (`6656c9d332735ca6a27725e0fb45a1715c4372d9`),
the last release before kulala-core. Compatibility and security fixes only.
It does not use Core, a license service, or upstream release binaries.
Upstream history, the MIT license, and attribution are retained.

## Install this fork

Install Neovim 0.10+, cURL, a C compiler, and tree-sitter-cli through trusted sources.
For JavaScript request scripts, also install Bun (build time) and Node.js (runtime).
No npm install is needed. The LSP is Lua code inside Neovim, not an external executable.

```lua
{
  "dkarter/kulala.nvim",
  name = "kulala-v5.nvim",
  main = "kulala",
  branch = "main",
  submodules = false,
  build = "scripts/build.lua",
  ft = { "http", "rest" },
  opts = { global_keymaps = true },
}
```

The build regenerates the parser C code from the bundled grammar, compiles it locally,
and builds the optional JavaScript helpers from TypeScript. Outputs stay in `.build/`.
The plugin loads that parser by its exact path, not from an existing shared parser cache.
Rebuild after updates; restart Neovim to replace an already-loaded native parser.

The separate **kulala-fmt executable and Postman/OpenAPI/Bruno converter are excluded**.
The built-in Lua formatter and LSP remain. JavaScript helpers no longer auto-install
npm dependencies. Diagnostics stay local and do not collect request/config snapshots.
Caches and state use the `dkarter-kulala-v5` namespace, separate from upstream.

Only execute `.http` files you trust: scripts, shell-command metadata, file includes,
and response redirects can execute code or read/write files with your permissions.
This fork is not a sandbox. See [SECURITY.md](SECURITY.md) for review scope and limitations.

The original README follows as historical documentation. Its upstream install,
formatter, badges, and service links do **not** describe this fork.

---

<div align="center">

![Kulala Logo](logo.svg)

# kulala.nvim

[![Made with love](assets/badge-made-with-love.svg)](https://github.com/mistweaverco/kulala.nvim/graphs/contributors)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/mistweaverco/kulala.nvim?style=for-the-badge)](https://github.com/mistweaverco/kulala.nvim/releases/latest)
[![Discord](assets/badge-discord.svg)](https://discord.gg/QyVQmfY4Rt)

[![Main status](https://img.shields.io/github/actions/workflow/status/mistweaverco/kulala.nvim/tests.yml?label=main&branch=main&style=for-the-badge)](https://github.com/mistweaverco/kulala.nvim/actions/workflows/tests.yml)
[![Develop status](https://img.shields.io/github/actions/workflow/status/mistweaverco/kulala.nvim/tests.yml?branch=develop&label=develop&style=for-the-badge)](https://github.com/mistweaverco/kulala.nvim/actions/workflows/tests.yml)

[Requirements](https://neovim.getkulala.net/docs/getting-started/requirements) • [Install](#install) • [Usage](https://neovim.getkulala.net/docs/usage) • [HTTP File Spec](https://neovim.getkulala.net/docs/usage/http-file-spec) • [Kulala GH Action](https://github.com/mistweaverco/kulala-github-action)

<p></p>

A fully-featured REST Client Interface for Neovim.

Kulala is swahili for "rest" or "relax".

It allows you to make HTTP requests from within Neovim.

<p></p>

![demo](./assets/demo.gif)

<p></p>

## Features
  
Protocols: HTTP, GRPC, GraphQL, WebSocket, Streaming

Specs: HTTP File Spec and IntelliJ HTTP Client compliant

Variables: Environment, Document, Request, Dynamic, Prompt, `http-client.env` files

Importing and running requests from external `*.http` files

Importing and saving request/response data to/from external files

JS and Lua scripting: Pre-request, Post-request, Conditional, Inline, External

Authentication: Basic, Bearer, Digest, NTLM, OAuth2, Negotiate, AWS, SSL

Response formatting and live filtering

Assertions, automated testing and reporting

Built-in LSP completion and formatting

Import/export to/from Postman, OpenAPI, Bruno

CLI tooling and CI hooks

Scratchpad: for making requests

100% Compatibility with IntelliJ HTTP Client

# •

Together with our standalone products [Kulala Language Server](https://github.com/mistweaverco/kulala-ls) and [Kulala Formatter](https://github.com/mistweaverco/kulala-fmt), we aim to provide the best REST Client experience on the web without leaving your favourite editor!

# ••

Kulala team loves feature requests and feedback, so if you have any ideas or suggestions, please let us know!  
We will be happy to implement them ❤️

</div>

## Install

> [!WARNING]
> Requires Neovim 0.10.0+ and cURL.
>
> See [requirements](https://neovim.getkulala.net/docs/getting-started/requirements).

Via [lazy.nvim](https://github.com/folke/lazy.nvim):

### Configuration

```lua
require("lazy").setup({
  {
    "mistweaverco/kulala.nvim",
    keys = {
      { "<leader>Rs", desc = "Send request" },
      { "<leader>Ra", desc = "Send all requests" },
      { "<leader>Rb", desc = "Open scratchpad" },
    },
    ft = {"http", "rest"},
    opts = {
      global_keymaps = false,
      global_keymaps_prefix = "<leader>R",
      kulala_keymaps_prefix = "",
    },
  },
})
```

> [!NOTE]
> By default global keymaps are disabled, change to `global_keymaps = true` to get a complete set of key mappings for Kulala. Check the [keymaps documentation](https://neovim.getkulala.net/docs/getting-started/keymaps) for details.

See complete [configuration options](https://neovim.getkulala.net/docs/getting-started/configuration-options) for more information.

## Honorable mentions

### rest.nvim

For getting this project started.

This project was heavily inspired by the idea of having a REST client in Neovim.

The actual state of [rest.nvim](https://github.com/rest-nvim/rest.nvim)
as archived kicked off the development of kulala.nvim.

### curl.nvim

If you want a simple scratchpad for making HTTP requests,
check out [curl.nvim](https://github.com/oysandvik94/curl.nvim)

It's very different to this project, but it's a great tool for making
HTTP requests from within Neovim and maybe just your cup of tea.

### httpbin.org

For providing a great service for testing HTTP requests and
making it in all the kulala examples.

Thanks for making it easy to test and develop this plugin.

[restnvim-unarchived-post]: https://github.com/rest-nvim/rest.nvim/issues/398#issue-2442747909
