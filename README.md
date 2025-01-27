# git-commit-tool.nvim

um plugin para neovim para aplicar patterns de commits git e evitar erros de digitaçao

## Install

# lazy

```lua
return {
  dir = "~/Documentos/git-commit-tool.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "dinhhuy258/git.nvim",
      opts = {}
    },
  },
  opts={
    templates = {
      ":sparkles: feat: {{COMMIT}}",
      ":bug: fix: {{COMMIT}}",
      ":construction: {{COMMIT}}",
      ":recycle: refactor: {{COMMIT}}",
    },
    keymaps = true
  },
}
```
