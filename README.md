# git-commit-tool.nvim

um plugin para neovim para aplicar patterns de commits git e evitar erros de digitaçao

## Install

# lazy

```lua
return {
  "francivaldo4334/git-commit-tool.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  opts={
    templates = {
      ":sparkles: feat: {{COMMIT}}",
      ":bug: fix: {{COMMIT}}",
      ":construction: {{COMMIT}}",
      ":recycle: refactor: {{COMMIT}}",
    },
    use_keymaps = true
  },
}
```
