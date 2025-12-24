-- =========================
-- 1) BOOTSTRAP PACKER
-- =========================
local fn = vim.fn
local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"

if fn.empty(fn.glob(install_path)) > 0 then
  fn.system({ "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path })
  vim.cmd("packadd packer.nvim")
end

local ok_packer, packer = pcall(require, "packer")
if not ok_packer then
  return
end

packer.startup(function(use)
  use "wbthomason/packer.nvim"

  -- Core deps
  use "nvim-lua/plenary.nvim"
  use "nvim-tree/nvim-web-devicons"

  -- UI
  use "folke/tokyonight.nvim"
  use { "nvim-lualine/lualine.nvim", requires = { "nvim-tree/nvim-web-devicons" } }
  use { "nvim-tree/nvim-tree.lua", requires = { "nvim-tree/nvim-web-devicons" } }
  use { "goolord/alpha-nvim", requires = { "nvim-tree/nvim-web-devicons" } }
  use "akinsho/bufferline.nvim"
  use "lukas-reineke/indent-blankline.nvim"
  use "lewis6991/gitsigns.nvim"

  -- Dev UX
  use "voldikss/vim-floaterm"
  use { "windwp/nvim-autopairs" }

  -- LSP / tooling
  use "neovim/nvim-lspconfig"
  use "williamboman/mason.nvim"
  use "williamboman/mason-lspconfig.nvim"

  -- Autocomplete / snippets
  use "hrsh7th/nvim-cmp"
  use "hrsh7th/cmp-nvim-lsp"
  use "L3MON4D3/LuaSnip"
  use "saadparwaiz1/cmp_luasnip"

  -- Telescope
  use { "nvim-telescope/telescope.nvim", requires = { "nvim-lua/plenary.nvim" } }

  -- Treesitter
  use { "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" }

  -- Markdown Preview
  use({ "iamcco/markdown-preview.nvim", run = "cd app && npm install", ft = { "markdown" } })
end)

-- =========================
-- 2) SETTINGS
-- =========================
vim.o.number = true
vim.o.relativenumber = true
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.g.mapleader = " "

-- =========================
-- 3) THEME (safe)
-- =========================
local ok_tokyo, tokyonight = pcall(require, "tokyonight")
if ok_tokyo then
  tokyonight.setup({
    style = "night",
    on_highlights = function(hl, c)
      hl.Comment  = { fg = "#00FF00" }
      hl.String   = { fg = "#FF5555" }
      hl.Keyword  = { fg = "#FF0000" }
      hl.Function = { fg = "#00FF00" }
    end,
  })
  vim.cmd("colorscheme tokyonight-night")
end

-- =========================
-- 4) PLUGIN CONFIG (safe requires)
-- =========================
local ok_lualine, lualine = pcall(require, "lualine")
if ok_lualine then lualine.setup() end

local ok_dev, devicons = pcall(require, "nvim-web-devicons")
if ok_dev then devicons.setup() end

-- NvimTree
vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { silent = true })

-- Telescope
vim.keymap.set("n", "<leader>f", ":Telescope find_files<CR>", { silent = true })

-- Floaterm
vim.g.floaterm_keymap_toggle = "<leader>t"
vim.g.floaterm_position = "bottom"
vim.g.floaterm_height = 0.3

vim.cmd([[
  tnoremap <Esc> <C-\><C-n>:FloatermToggle<CR>
]])

-- Alpha dashboard (safe)
local ok_alpha, alpha = pcall(require, "alpha")
if ok_alpha then
  local dashboard = require("alpha.themes.dashboard")
  dashboard.section.header.val = {
    " █████╗ ██╗  ██╗██████╗ ",
    "██╔══██╗██║  ██║██╔══██╗",
    "███████║███████║██████╔╝",
    "██╔══██║██╔══██║██╔═██║ ",
    "██║  ██║██║  ██║██║ ██║ ",
    "╚═╝  ╚═╝╚═╝  ╚═╝╚═╝ ╚═╝ ",
    "   WELCOME TO SITH LAB   ",
  }
  dashboard.section.footer.val = "Tecnología, Fuerza y Precisión. Que el código te guíe."
  alpha.setup(dashboard.config)
end

-- Markdown preview
vim.g.mkdp_auto_start = 1
