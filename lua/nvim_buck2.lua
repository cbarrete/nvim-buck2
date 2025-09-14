-- The last target picked by the user. Stored so that it can be immediately
-- reused rather than interactively selected over and over.
local last_picked_target = nil

vim.g.buck2 = vim.g.buck2 or "buck2"

-- Runs `vim.ui.select` synchronously.
local function blocking_select(items, opts)
    local co = assert(coroutine.running())
    local select_fn = function()
        vim.ui.select(
            items,
            opts,
            function(choice)
                coroutine.resume(co, choice)
            end
        )
    end
    vim.schedule(select_fn)
    return coroutine.yield()
end

-- Runs a command and returns its standard output.
local function run(cmd)
    local output = vim.system(cmd):wait()
    assert(
        output.code == 0,
        ('Failed to run `%s`.\nstdout:\n%s\nstderr:\n%s'):format(vim.inspect(cmd), output.stdout, output.stderr)
    )
    return vim.trim(output.stdout)
end

-- Runs a query-like command and prompts the user in case multiple choices are available.
local function pick_query(cmd, select_opts)
    local choices = vim.split(run(cmd), '\n', {trimempty = true})
    if #choices == 1 then
        return choices[1]
    else
        return blocking_select(choices, select_opts)
    end
end

local function build(target)
    -- TODO: Async, with `vim.notify` progress notifications.
    -- TODO: Populate quickfix list with build errors.
    return run({vim.g.buck2, 'build', '--show-full-simple-output', target})
end

-- Build the target owning the current file and return its output path.
-- Prompts the user if multiple choices are available.
local function current_file()
    local owner = pick_query(
        {vim.g.buck2, 'uquery', ('owner(%s)'):format(vim.fn.expand('%:p'))},
        {prompt = 'Pick an owning target: '}
    )

    local debug_target = pick_query(
        {vim.g.buck2, 'uquery', ('rdeps(//..., %s)'):format(owner)},
        {prompt = 'Pick the target to debug: '}
    )

    last_picked_target = debug_target

    return build(debug_target)
end

-- Select a target, build it and return its output path.
local function select_target()
    local target = pick_query({vim.g.buck2, 'targets', '//...'}, {prompt = 'Pick a target: '})
    last_picked_target = target
    return target
end

-- Build the last picked target and return its output path.
local function last_target()
    return build(last_picked_target)
end

-- Jumps to the build file that owns the current file.
local function go_to_build_file()
    local build_file = run({vim.g.buck2, 'uquery', ('buildfile(owner(%s))'):format(vim.fn.expand('%:p'))})
    vim.cmd.edit(build_file)
end

return {
    dap = {
        current_file = current_file,
        select_target = select_target,
        last_target = last_target,
    },
    go_to_build_file = go_to_build_file,
}
