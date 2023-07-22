# `nvim-treesitter`-based actions on JavaScript code

I would have considered as `null-ls` code actions but unfortunately that project is retiring.

## with `lazy.nvim`
```lua
local js_filetypes = {
  "javascript",
  "javascriptreact",
  "typescript",
  "typescriptreact",
}

return {
  {
    "llllvvuu/nvim-js-actions",
    ft = js_filetypes,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    init = function()
      vim.api.nvim_create_autocmd(
        "FileType",
        {
          pattern = js_filetypes,
          command = "nnoremap <buffer> <leader>ta " ..
            ":lua require('nvim-js-actions').js_arrow_fn.toggle()<CR>"
            -- can also do `require('nvim-js-actions/js-arrow-fn').toggle()`
        }
      )
    end
  }
}
```

## `js_arrow_fn`
Toggles between `function` and `=>` syntax.

https://github.com/llllvvuu/nvim-js-actions/assets/5601392/69d436f2-4801-4521-8e58-3e22810914ed
