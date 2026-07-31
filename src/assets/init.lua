-- dev-env init.lua — 轻量、高性能 nvim 配置
-- 原则: 无动效、无多余装饰; 只保留提升开发效率的组件; 插件全部按需加载。

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 基础选项
vim.g.mapleader = " "
vim.g.maplocalleader = " "
local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.termguicolors = true
opt.mouse = "a"
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true
opt.wrap = false
opt.scrolloff = 8
opt.updatetime = 300
opt.swapfile = false
opt.undofile = true
opt.ignorecase = true
opt.smartcase = true
opt.splitright = true
opt.splitbelow = true
opt.completeopt = { "menu", "menuone", "noselect" }
opt.laststatus = 2

require("lazy").setup({
  -- 配色: 纯 lua, 无动画, 开销极小
  { "folke/tokyonight.nvim", lazy = false, priority = 1000, opts = { style = "storm" } },

  -- 模糊查找
  { "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "文件" },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "全局搜索" },
      { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "缓冲区" },
      { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "帮助" },
    },
    opts = { pickers = { find_files = { hidden = true } } },
  },

  -- 语法高亮 / 缩进
  { "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = "VeryLazy",
    main = "nvim-treesitter",
    opts = {
      ensure_installed = {
        "lua", "vim", "vimdoc", "rust",
        "typescript", "tsx", "javascript",
        "html", "css", "json", "yaml", "toml", "markdown",
      },
      highlight = { enable = true },
      indent = { enable = true },
    },
  },

  -- LSP 生态
  { "williamboman/mason.nvim", cmd = "Mason", opts = {} },
  { "williamboman/mason-lspconfig.nvim",
    dependencies = { "mason.nvim" },
  },
  { "neovim/nvim-lspconfig",
    dependencies = { "williamboman/mason-lspconfig.nvim" },
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local has_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
      local caps = has_cmp and cmp_nvim_lsp.default_capabilities() or vim.lsp.protocol.make_client_capabilities()
      vim.lsp.config("*", { capabilities = caps })
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
      })
      vim.lsp.config("rust_analyzer", {
        settings = { ["rust-analyzer"] = { check = { command = "clippy" } } },
      })
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local bufnr = args.buf
          local map = function(mode, keys, fn, desc)
            vim.keymap.set(mode, keys, fn, { buffer = bufnr, desc = desc })
          end
          map("n", "gd", vim.lsp.buf.definition, "跳转定义")
          map("n", "gr", vim.lsp.buf.references, "查找引用")
          map("n", "K", vim.lsp.buf.hover, "悬停文档")
          map("n", "gD", vim.lsp.buf.declaration, "声明位置")
          map("n", "<leader>rn", vim.lsp.buf.rename, "重命名")
          map("n", "<leader>ca", vim.lsp.buf.code_action, "代码操作")
          map("n", "<leader>f", function() vim.lsp.buf.format({ async = true }) end, "格式化")
        end,
      })
      require("mason").setup({})
      require("mason-lspconfig").setup({
        ensure_installed = {
          "rust_analyzer", "ts_ls",
          "lua_ls", "html", "cssls", "jsonls", "yamlls", "tailwindcss",
        },
        automatic_enable = true,
      })
    end,
  },

  -- 补全 (轻量)
  { "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      cmp.setup({
        snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
        mapping = cmp.mapping.preset.insert({
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },

  -- 保存即格式化
  { "stevearc/conform.nvim",
    event = { "BufWritePre" },
    opts = {
      formatters_by_ft = {
        rust = { "rustfmt" },
        lua = { "stylua" },
        javascript = { "prettierd" },
        typescript = { "prettierd" },
        javascriptreact = { "prettierd" },
        typescriptreact = { "prettierd" },
        json = { "prettierd" },
        jsonc = { "prettierd" },
        css = { "prettierd" },
        html = { "prettierd" },
        markdown = { "prettierd" },
        yaml = { "prettierd" },
      },
      format_on_save = { timeout_ms = 1200, lsp_fallback = true },
    },
  },

  -- 行内 git 状态
  { "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
  },

  -- 按键提示 (轻量, 仅触发时加载)
  { "folke/which-key.nvim", event = "VeryLazy", opts = {} },

  -- 状态栏: 用 mini 系, 比 lualine 更省资源
  { "echasnovski/mini.statusline", event = "VeryLazy", opts = {} },
}, {
  checker = { enabled = false },
  performance = { cache = { enabled = true }, reset_packpath = true },
})

vim.cmd.colorscheme("tokyonight-storm")
