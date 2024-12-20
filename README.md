# nvim-buck2

This is a collection of helpers to better integrate Buck2 with Neovim.

This plugin makes no support/stability guarantees for now.

## Usage

### nvim-dap integration

`nvim-buck2` provides some helper functions to integrate Buck2 and [nvim-dap](https://github.com/mfussenegger/nvim-dap):

- `dap.current_file` can be used to debug the current file. If the current file is not a leaf owned by a single target, `vim.ui.select` will be called to select a target.
- `dap.select_target` can be used to debug any target, picked via `vim.ui.select`.
- `dap.current_file` can be used to debug the last debugged file again. This is different from nvim-dap's `run_last`, as the latter would invoke the picker on each run.

```lua
local common_lldb_dap_config = {
    type = 'lldb',
    request = 'launch',
    cwd = '${workspaceFolder}',
    runInTerminal = true,
}

local buck2 = require('nvim_buck2')
dap.configurations.cpp = {
    vim.tbl_extend('error', common_lldb_dap_config, {
        name = '[Buck2] Debug current file',
        program = buck2.dap.current_file,
    }),
    vim.tbl_extend('error', common_lldb_dap_config, {
        name = '[Buck2] Debug any target',
        program = buck2.dap.select_target,
    }),
    vim.tbl_extend('error', common_lldb_dap_config, {
        name = '[Buck2] Debug last target',
        program = buck2.dap.last_target,
    }),
}
dap.configurations.c = dap.configurations.cpp
dap.configurations.rust = dap.configurations.cpp
```

### Custom Buck2 binary

By default, nvim-buck2 expects a `buck2` binary to be available on the `PATH`.

You can set `vim.g.buck2` to use a custom Buck2 binary (e.g. if you have a local build you want to use, or you use a launcher like [Buckle](https://github.com/benbrittain/buckle)):

```lua
vim.g.buck2 = 'buckle'
```
