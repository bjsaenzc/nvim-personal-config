return {
    "ldelossa/gh.nvim",
    cmd = { "GH", "GHOpenPR", "GHOpenIssue", "GHSearchPRs", "GHSearchIssues", "GHReviewStart" },
    dependencies = {
        {
        "ldelossa/litee.nvim",
        config = function()
            require("litee.lib").setup()
        end,
        },
    },
    config = function()
        require("litee.gh").setup()
    end,
}

