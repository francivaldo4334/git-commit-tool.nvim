local popup = require("plenary.popup")
local TEMPLATES = {}
local M = {}
local borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }
local function getArgs(event)
	local argsstring = event.args or ""
	local args = {}
	for arg in argsstring:gmatch("[^%s]+") do
		table.insert(args, arg)
	end
	return args
end

M.setToken = function(username, token)
	vim.cmd(": lua require('git.cmd').cmd('git config --global credential.helper store')")
	vim.cmd(": lua git.cmd('git config --global credential.helper store')")
	vim.fn.system(string.format('echo "https://%s:%s@github.com" > ~/.git-credentials', username, token))
end
local function getGitFileNoCommited()
	local handle = vim.fn.system("git status --porcelain") .. "\n"
	local files = {}
	for line in handle:gmatch("[^\r\n]+") do
		local status, file = line:match("^%s*(%S+)%s+(.*)")
		if status and (status == "MM" or status == "M" or status == "??") then
			table.insert(files, "( ):" .. file)
		end
	end
	return files
end
local function popupMultiselection(title, items, on_select_items, default_line)
	local options = {}
	local nextOption = "[AVANÇAR]"
	for _, value in ipairs(items) do
		table.insert(options, value)
	end
	table.insert(options, nextOption)
	local win_id = popup.create(options, {
		title = title,
		cursorline = true,
		enter = true,
		borderchars = borderchars,
		callback = function(_, cel)
			if cel == nextOption then
				local select_items = {}
				for _, item in ipairs(items) do
					if not item:match("%(%s*%):") then
						table.insert(select_items, item:sub(#"(x):" + 1))
					end
				end
				on_select_items(select_items)
			else
				for i, item in ipairs(items) do
					if item == cel then
						if cel:match("%(%s*%):") then
							items[i] = cel:gsub("^%(%s*%):(.*)", "(x):%1")
						else
							items[i] = cel:gsub("^%(x*%):(.*)", "( ):%1")
						end
						default_line = i
					end
				end
				popupMultiselection(title, items, on_select_items, default_line)
			end
		end,
	})
	vim.api.nvim_win_set_cursor(win_id, { default_line or 1, 0 })
end
local function popupSelectTemplate(on_select)
	popup.create(TEMPLATES, {
		title = "Selecionar template",
		cursorline = true,
		borderchars = borderchars,
		enter = true,
		callback = function(_, cel)
			on_select(cel)
		end,
	})
end
---@param template string
local function applyTemplate(template, on_commit)
	local commit = template
	local vars = {}
	local key = 0
	local value = ""
	for it in template:gmatch("{{%S+}}") do
		table.insert(vars, it)
	end
	local function popupSetVar(var)
		popup.create("", {
			title = "Insira o valor de " .. var,
			lines = 1,
			width = 40,
			height = 4,
			borderchars = borderchars,
			enter = true,
			callback = function(win_id, _)
				local buf = vim.api.nvim_win_get_buf(win_id)
				local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
				local text = table.concat(lines, "\n")
				commit = commit:gsub(var, text)
				key, value = next(vars, key)
				if value then
					popupSetVar(value)
				else
					-- vim.api.nvim_win_close(win_id, true)
					on_commit(commit)
				end
			end,
		})
	end
	key, value = next(vars)
	popupSetVar(value)
end
function M.buildCommitUi()
	local files = getGitFileNoCommited()
	popupMultiselection("Adicionar arquivos ao commit", files, function(selectedItems)
		popupSelectTemplate(function(template)
			applyTemplate(template, function(commit)
				local commandAdd = "add " .. table.concat(selectedItems, " ")
				local commandCommit = "commit -m '" .. commit:gsub("'", "\\'") .. "'"
				print(commandAdd)
				print(commandCommit)
				vim.cmd(":Git " .. commandAdd)
				vim.cmd(":Git " .. commandCommit)
				-- vim.cmd("lua require('git.cmd').cmd('add " ..  .. "')")
				-- vim.cmd("lua require('git.cmd').cmd('commit -m \"" .. commit .. "\")")
			end)
		end)
	end)
end

M.setup = function(opts)
	TEMPLATES = opts.templates
	if vim.fn.executable("git") == 0 then
		vim.notify(
			"git-commit-tool: Git não está instalado! Este plugin pode não funcionar corretamente.",
			vim.log.levels.ERROR
		)
	end

	-- define comandos
	vim.api.nvim_create_user_command("GitCommitToolSetCredentials", function(event)
		local args = getArgs(event)
		local username = args[0]
		local token = args[1]
		if not username or not token then
			vim.notify("O commando espera por dois parametros <username> e <token>", vim.log.levels.ERROR)
		else
			M.setToken(username, token)
		end
	end, {
		nargs = "*",
		desc = "Define as credenciais do github <username> e <token>",
	})
	vim.api.nvim_create_user_command("GitCommitToolAddCommit", M.buildCommitUi, {
		nargs = 0,
		desc = "Inicia a construção de um commit",
	})
end
return M
