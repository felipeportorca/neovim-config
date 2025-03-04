vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.sql",
  callback = function(args)
    require("conform").format({
      bufnr = args.buf,
      formatters = { "sqlfluff" },
      timeout_ms = 200000,
      quiet = true
    })
  end,
})
