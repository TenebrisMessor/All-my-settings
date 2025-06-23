-- Packer plugins
require('packer').startup(function(use)
  use 'wbthomason/packer.nvim' -- Packer en sí
  use 'nvim-lualine/lualine.nvim' -- barra de estado pro
  use 'kyazdani42/nvim-tree.lua' -- explorador de archivos
  use 'nvim-telescope/telescope.nvim' -- buscador tipo VSCode
  use 'neovim/nvim-lspconfig' -- soporte para lenguajes
  use 'hrsh7th/nvim-cmp' -- autocompletado
  use 'hrsh7th/cmp-nvim-lsp' --Fuente LSP para cmp
  use 'folke/tokyonight.nvim' --Tema
  use 'nvim-tree/nvim-web-devicons' --Iconos bonitos
  use 'goolord/alpha-nvim' -- Dashboard de bienvenida
  use 'nvim-lua/plenary.nvim' -- Requisito para alpha
  -- Treesitter para resaltar código
  use {'nvim-treesitter/nvim-treesitter', run = ':TSUpdate'} --Resaltado de sintaxis moderno
  use 'voldikss/vim-floaterm' -- Terminal flotante
  use({ 'iamcco/markdown-preview.nvim', run = 'cd app && npm install', ft = { 'markdown' } }) --Preview Markdown
  -- Plugins estilo VS Code
  use 'nvim-lua/plenary.nvim'                         -- Requisito para telescope
  use 'williamboman/mason.nvim'                       -- Instalador de servidores LSP
  use 'williamboman/mason-lspconfig.nvim'             -- Bridge entre mason y lspconfig
  use 'L3MON4D3/LuaSnip'                              -- Snippets
  use 'saadparwaiz1/cmp_luasnip'                      -- Fuente de snippets para cmp
  use 'glepnir/dashboard-nvim'                        -- Dashboard tipo VS Code
  use 'akinsho/bufferline.nvim'                       -- Barra de pestañas estilo VSCode
  use 'lewis6991/gitsigns.nvim'                       -- Indicadores Git al costado
  use 'lukas-reineke/indent-blankline.nvim'           -- Guías de indentación
  use 'windwp/nvim-autopairs'                         -- Cierre automático de paréntesis
end)

-- Configuración general
vim.o.number = true
vim.o.relativenumber = true
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.g.mapleader = ' '
-- Lualine
require('lualine').setup()

-- NvimTree
vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>')

-- Telescope
  vim.keymap.set('n', '<leader>f', ':Telescope find_files<CR>')


-- Terminal flotante (Sith Toggle)
vim.g.floaterm_keymap_toggle = '<leader>t'  -- Abrir/cerrar con SPC + t
vim.g.floaterm_position = 'bottom'          -- Posición inferior
vim.g.floaterm_height = 0.3                 -- 30% de la pantalla

-- Salir con Esc desde la terminal
vim.cmd([[
  tnoremap <Esc> <C-\><C-n>:FloatermToggle<CR>
]])
-- Iconos
require('nvim-web-devicons').setup()

-- Tema Sith
vim.cmd[[colorscheme tokyonight-night]]

-- Dashboard personalizado
local alpha = require("alpha")
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

require("tokyonight").setup({
  style = "night", -- o "storm" si quieres más contraste
  on_colors = function(colors)
    colors.comment = "#00FF00"  -- Verde neó
    colors.string = "#FF5555"   -- Rojo suave
    colors.keyword = "#FF0000"  -- Rojo fuerte
    colors.functionStyle = { fg = "#00FF00" }
  end,
})
vim.cmd[[colorscheme tokyonight-night]]
vim.cmd([[
  let g:mkdp_auto_start = 1
]])
