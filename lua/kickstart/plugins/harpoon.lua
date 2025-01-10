local harpoon = require 'harpoon'

-- Setup key mappings
vim.keymap.set('n', '<leader>A', function()
  harpoon.mark.add_file()
end, { desc = 'Add file to Harpoon' })
vim.keymap.set('n', '<leader>h', function()
  harpoon.ui.toggle_quick_menu()
end, { desc = 'Toggle Harpoon menu' })

-- Navigate to files in Harpoon
for i = 1, 5 do
  vim.keymap.set('n', '<leader>' .. i, function()
    harpoon.ui.nav_file(i)
  end, { desc = 'Navigate to file ' .. i })
end

-- Additional key mappings for navigating previous and next files
vim.keymap.set('n', '<C-S-P>', function()
  harpoon.ui.prev()
end, { desc = 'Previous Harpoon file' })
vim.keymap.set('n', '<C-S-N>', function()
  harpoon.ui.next()
end, { desc = 'Next Harpoon file' })
