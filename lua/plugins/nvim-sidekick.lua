return {
  "folke/sidekick.nvim",
  lazy = false,
  opts = {
    -- add any options here
    cli = {
      -- mux = {
      --   backend = "tmux",
      --   enabled = true,
      -- :},
      tools = {
        cursor = {
            cmd = { "cursor-agent" },
            keys = {
            },
        },
      },
      prompts = {
        python_tests = "Using @pytest_rules create a minimal set of tests for {this}",
        module_docstring = "Generate module, class, and method docstrings for {this}",
        update_changelog = "Update @CHANGELOG.md file with implemented changes, namely:",
        pr_documentation = "Create a markdown PR documentation file in LATIN AMERICAN SPANISH, comparing changes with respect to `develop` git branch. The file must include at least following sections: ## **¿Qué implementa este PR*?? --> Main changes this pull request implements ## **¿Cómo probarlo? --> Include minimal `curls` with case test scenarios",
        custom = function(ctx)
          return "Current file: " .. ctx.buf .. " at line " .. ctx.row
        end,
      },
    },
  },
  keys = {
    -- {
      -- "<tab>",
      -- function()
      --   -- if there is a next edit, jump to it, otherwise apply it if any
      --   if not require("sidekick").nes_jump_or_apply() then
      --    return "<Tab>" -- fallback to normal tab
      --  end
      -- end,
      -- expr = true,
      -- desc = "Goto/Apply Next Edit Suggestion",
    -- },
    {
      "<c-.>",
      function() require("sidekick.cli").toggle() end,
      desc = "Sidekick Toggle",
      mode = { "n", "t", "i", "x" },
    },
    {
      "<leader>aa",
      function() require("sidekick.cli").toggle() end,
      desc = "Sidekick Toggle CLI",
    },
    {
      "<leader>as",
      -- function() require("sidekick.cli").select() end,
      -- Or to select only installed tools:
      function() require("sidekick.cli").select({ filter = { installed = true } }) end,
      desc = "Select CLI",
    },
    {
      "<leader>ad",
      function() require("sidekick.cli").close() end,
      desc = "Detach a CLI Session",
    },
    {
      "<leader>at",
      function() require("sidekick.cli").send({ msg = "{this}" }) end,
      mode = { "x", "n" },
      desc = "Send This",
    },
    {
      "<leader>af",
      function() require("sidekick.cli").send({ msg = "{file}" }) end,
      desc = "Send File",
    },
    {
      "<leader>av",
      function() require("sidekick.cli").send({ msg = "{selection}" }) end,
      mode = { "x" },
      desc = "Send Visual Selection",
    },
    {
      "<leader>ap",
      function() require("sidekick.cli").prompt() end,
      mode = { "n", "x" },
      desc = "Sidekick Select Prompt",
    },
    -- Example of a keybinding to open Claude directly
    {
      "<leader>ac",
      function() require("sidekick.cli").toggle({ name = "claude", focus = true }) end,
      desc = "Sidekick Toggle Claude",
    },
  },
}