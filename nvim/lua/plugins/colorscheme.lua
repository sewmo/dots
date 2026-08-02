return {
  {
    "rktjmp/lush.nvim",
  },
  {
    "oncomouse/lushwal.nvim",
    dependencies = {
      "rktjmp/lush.nvim",
      "rktjmp/shipwright.nvim",
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "lushwal",
    },
    config = function(_, opts)
      require("lazyvim").setup(opts)

      local function lighten(hex, amount)
        hex = hex:gsub("#", "")
        local r = tonumber(hex:sub(1, 2), 16)
        local g = tonumber(hex:sub(3, 4), 16)
        local b = tonumber(hex:sub(5, 6), 16)

        r = math.min(255, math.floor(r + (255 - r) * amount))
        g = math.min(255, math.floor(g + (255 - g) * amount))
        b = math.min(255, math.floor(b + (255 - b) * amount))

        return string.format("#%02x%02x%02x", r, g, b)
      end

      local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
      local bg = string.format("#%06x", normal.bg)

      vim.api.nvim_set_hl(0, "CursorLine", {
        bg = lighten(bg, 0.10), -- 10% lighter than background
      })

      vim.api.nvim_set_hl(0, "CursorLineNr", {
        bold = true,
      })
    end,
  }
}
