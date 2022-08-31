vim.cmd [[packadd packer.nvim]]

vim.g.catppuccin_flavour = "mocha"

return require('packer').startup(function(use)
    use 'wbthomason/packer.nvim'

    use { "catppuccin/nvim", as = "catppuccin" }

    use {
        'nvim-lualine/lualine.nvim',
        requires = { 'kyazdani42/nvim-web-devicons', opt = true }
    }

    -- setup
    require('lualine').setup()
    require("catppuccin").setup()
end)

