local popup = require("plenary.popup")
local M = {}
M.TEMPLATES = {}
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
	M.run_command("git config --global credential.helper store")
	M.run_command(string.format('echo "https://%s:%s@github.com" > ~/.git-credentials', username, token))
end
function M.getGitFileNoCommited()
	local handle = vim.fn.system("git status --porcelain") .. "\n"
	local files = {}
	for line in handle:gmatch("[^\r\n]+") do
		local status, file = line:match("^%s*(%S+)%s+(.*)")
		table.insert(files, "( ):" .. status .. " " .. file)
	end
	return files
end

function M.popupMultiselection(title, items, on_select_items, default_line)
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
				M.popupMultiselection(title, items, on_select_items, default_line)
			end
		end,
	})
	vim.api.nvim_win_set_cursor(win_id, { default_line or 1, 0 })
end

function M.popupSelectTemplate(on_select)
	popup.create(M.TEMPLATES, {
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
function M.applyTemplate(template, on_commit)
	local commit = template
	local vars = {}
	local key = 0
	local value = ""
	for it in template:gmatch("{{%S+}}") do
		table.insert(vars, it)
	end
	local function popupSetVar(var)
		local text = vim.fn.input("Insira o valor de " .. var)
		commit = commit:gsub(var, text)
		key, value = next(vars, key)
		if value then
			popupSetVar(value)
		elseif #commit > 0 then
			on_commit(commit)
		end
	end
	key, value = next(vars)
	popupSetVar(value)
end

function M.run_command(command, callback)
	local result = vim.fn.system(command)
	if vim.v.shell_error == 0 then
		-- vim.notify("Comando executado com sucesso: " .. command)
		if callback then
			callback(result)
		end
		return true
	else
		vim.notify(string.format("Erro ao executar comando: %s, error: %s", command, result), vim.log.levels.ERROR)
		return false
	end
end

function M.buildCommitUi()
	local files = M.getGitFileNoCommited()
	table.insert(files, "( ):AL .")
	M.popupMultiselection("Adicionar arquivos ao commit", files, function(selectedItems)
		for i, item in ipairs(selectedItems) do
			selectedItems[i] = item:sub(3)
		end
		M.popupSelectTemplate(function(template)
			M.applyTemplate(template, function(commit)
				local coro = coroutine.create(function()
					local handledCommit = commit:gsub("'", "\\'")
					local handledAdd = table.concat(selectedItems, " ")
					M.run_command("git rev-parse --show-toplevel", function(path)
						if vim.fn.isdirectory(path) == 0 then
							M.run_command(string.format("cd %s\n git add %s", path, handledAdd), function()
								M.run_command(string.format("git commit -m \"%s\"", handledCommit), function()
									M.run_command("git push", function()
										vim.notify("Commit realizado com sucesso!")
									end)
								end)
							end)
						end
					end)
				end)
				coroutine.resume(coro)
			end)
		end)
	end)
end

M.setup = function(opts)
	M.TEMPLATES = opts.templates
	local keymaps = opts.usekeymaps
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
	if keymaps then
		vim.api.nvim_set_keymap("n", "<Leader>G", ":GitCommitToolAddCommit<CR>", { silent = true })
	end
end
return M
