local M = {}
local function getArgs(event)
  local argsstring = event.args or ""
  local args = {}
  local i = 0
  for arg in string.gmatch(argsstring, "[^%s]+") do
    args[i] = arg
    i = i + 1
  end
  return args
end
M.setToken = function(username, token)
  vim.fn.system("git config --global credential.helper store")
  vim.fn.system(string.format('echo "https://%s:%s@github.com" > ~/.git-credentials', username, token))
end
M.setup = function()
  if vim.fn.executable("git") == 0 then
    vim.notify("git-commit-tool: Git não está instalado! Este plugin pode não funcionar corretamente.",
      vim.log.levels.ERROR)
  end

  -- define comandos
  vim.api.nvim_create_user_command(
    "GitCommitToolSetCredentials",
    function(event)
      local args = getArgs(event)
      local username = args[0]
      local token = args[1]
      if not username or not token then
        vim.notify("O commando espera por dois parametros <username> e <token>", vim.log.levels.ERROR)
      else
        M.setToken(username, token)
      end
    end,
    {
      nargs = "*",
      desc = "Define as credenciais do github <username> e <token>"
    }
  )
end
return M
