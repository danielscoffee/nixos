local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
	"git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	"wakatime/vim-wakatime",
	"neoclide/coc.nvim",
	"https://github.com/ThePrimeagen/vim-be-good",
	"https://github.com/mbbill/undotree",
	"https://github.com/tpope/vim-fugitive",
	'mrcjkb/haskell-tools.nvim',
	'prettier/vim-prettier',
	--"https://github.com/github/copilot.vim",
--"lervag/vimtex",	
	"https://github.com/tiagovla/tokyodark.nvim",
	"https://github.com/rebelot/kanagawa.nvim",
	"folke/tokyonight.nvim",
	"https://github.com/github/copilot.vim",
	require("dnvim.plugins.yazi"),
	require("dnvim.plugins.colorscheme"),
	require("dnvim.plugins.harpoon"),
	require("dnvim.plugins.gitsigns"),
	require("dnvim.plugins.autopairs"),
	require("dnvim.plugins.cmp"),
	require("dnvim.plugins.todo"),
	require("dnvim.plugins.telescope"),
	require("dnvim.plugins.lsp"),
	require("dnvim.plugins.discord"),
	require("dnvim.plugins.treesitter"),
})

-- vim.g.vimtex_view_method = "zathura"
-- vim.g.maplocalleader = ","
-- 
-- vim.o.foldmethod = "expr"
-- vim.o.foldexpr="vimtex#fold#level(v:lnum)"
-- vim.o.foldtext="vimtex#fold#text()"
-- vim.o.foldlevel=2
