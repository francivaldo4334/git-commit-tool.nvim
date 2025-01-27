local M = {}
M.setup = function()
  if vim.fn.executable("git") == 0 then
    vim.notify("git-commit-tool: Git não está instalado! Este plugin pode não funcionar corretamente.",
      vim.log.levels.ERROR)
  end
end
return M
