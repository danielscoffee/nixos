vim.g.mapleader = " "

vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- REMAPS
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("n", "<F5>", vim.cmd.UndotreeToggle)
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("n", "<leader>a", '<cmd>lua require("harpoon.mark").add_file()<CR>')
vim.keymap.set("n", "<leader>s", '<cmd>Telescope flutter commands<CR>')
vim.keymap.set("n", "<leader>l", '<cmd>lua require("harpoon.ui").toggle_quick_menu()<CR>')
vim.keymap.set("n", "<leader>g", '<cmd>Git<CR>')
