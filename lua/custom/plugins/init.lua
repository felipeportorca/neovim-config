-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
local plugins = {
  'jose-elias-alvarez/null-ls.nvim',
  ft = { 'python' },
  opts = function()
    return require 'custom.configs.null-ls'
  end,
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = true,
    -- use opts = {} for passing setup options
    -- this is equivalent to setup({}) function
  },
}

return plugins
