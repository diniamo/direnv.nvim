local M = {
    config = {
        direnv = "direnv",
        auto_load = false,
        watch_envrc = false
    }
}

function M.allow(callback)
    vim.system({ M.config.direnv, "allow" }, {}, callback)
    vim.notify(".envrc allowed")
end

function M.deny()
    vim.system({ M.config.direnv, "deny" })
    vim.notify(".envrc denied")
end

function M.reload()
    -- This variable based approach is required, because unset opts are
    -- inherated in replaced notifications, and we can't override them, because
    -- setting something to nil means it's not in the table
    local keep = true
    local notification = vim.notify("Loading .envrc...", nil, { keep = function() return keep end })

    vim.system(
        { M.config.direnv, "export", "vim" },
        { text = true },
        vim.schedule_wrap(function(obj)
            vim.fn.execute(obj.stdout)

            vim.notify(".envrc loaded", nil, { replace = notification })
            keep = false
        end)
    )
end
local schedule_reload = vim.schedule_wrap(M.reload)

local function get_rc(callback)
    vim.system(
        { M.config.direnv, "status", "--json" },
        { text = true },
        function(obj) callback(vim.json.decode(obj.stdout).state.foundRC) end
    )
end

function M.check()
    get_rc(
        function(rc)
            if rc == vim.NIL then
                return
            end

            if rc.allowed == 0 then
                schedule_reload()
                return
            end

            vim.schedule(function()
                local choice = vim.fn.confirm(rc.path .. " is denied.", "&Allow\n&Ignore", 2)

                if choice == 1 then
                    M.allow(schedule_reload)
                end
            end)
        end
    )
end

local watch_handle = nil
local function update_watch()
    if watch_handle then
        vim.uv.fs_event_stop(watch_handle)
    end

    get_rc(function(rc)
        if rc == vim.NIL then
            return
        end

        watch_handle = vim.uv.new_fs_event()
        vim.uv.fs_event_start(watch_handle, rc.path, {}, function(_, _, events)
            if events.change then
                schedule_reload()
            end
        end)
    end)
end

function M.setup(user_config)
    if user_config then
        M.config = vim.tbl_deep_extend("force", M.config, user_config)
    end

    if vim.fn.executable(M.config.direnv) ~= 1 then
        vim.notify(M.config.direnv .. " is not executable.", vim.log.levels.ERROR)
        return
    end

    vim.api.nvim_create_user_command("Direnv", function(cmd)
        if cmd.args == "reload" then
            M.reload()
        elseif cmd.args == "allow" then
            M.allow()
        elseif cmd.args == "deny" then
            M.deny()
        else
            vim.notify("Invalid subcommand: " .. cmd.args, vim.log.levels.ERROR)
        end
    end, { nargs = 1 })

    local group = vim.api.nvim_create_augroup("direnv_nvim", {})

    if M.config.auto_load then
        M.check()

        vim.api.nvim_create_autocmd("DirChanged", {
            group = group,
            pattern = "global",
            callback = M.check
        })
    end

    if M.config.watch_envrc then
        update_watch()

        vim.api.nvim_create_autocmd("DirChanged", {
            group = group,
            pattern = "global",
            callback = update_watch
        })
    end
end

return M
