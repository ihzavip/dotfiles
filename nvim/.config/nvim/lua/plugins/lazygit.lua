return {
  {
    "snacks.nvim",
    opts = {
      lazygit = {
        config = {
          os = {
            edit = 'sh -c "[ -n \\"$NVIM\\" ] && nvim --server $NVIM --remote {{filename}} || nvim {{filename}} &"',
            open = 'sh -c "[ -n \\"$NVIM\\" ] && nvim --server $NVIM --remote {{filename}} || nvim {{filename}} &"',
          },
        },
      },
    },
  },
}
