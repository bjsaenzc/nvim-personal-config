return {
	"3rd/diagram.nvim",
	ft = "markdown",
	dependencies = {
		{
			"3rd/image.nvim",
		},
	},
	config = function(_, opts)
		-- diagram.nvim keys its Mermaid cache only by source text. Without this
		-- discriminator, an image rendered before a renderer-option change is
		-- reused indefinitely, so changes to scale/size appear to do nothing.
		local mermaid = require("diagram.renderers.mermaid")
		local render = mermaid.render
		mermaid.render = function(source, renderer_opts)
			renderer_opts = renderer_opts or {}
			local options_hash = vim.fn.sha256(vim.inspect(renderer_opts))
			return render(source .. "\n%% diagram-render-options: " .. options_hash, renderer_opts)
		end

		require("diagram").setup(opts)
	end,
	opts = {
		events = {
			render_buffer = {},
			clear_buffer = { "BufLeave" },
		},
		renderer_options = {
			mermaid = {
				background = "transparent",
				theme = "dark",
				-- Produces a sufficiently large source image; image.nvim then fits it
				-- to the configured terminal-window bounds.
				scale = 2,
				width = 1600,
				height = 1200,
			},
		},
	},
	keys = {
		{
			"<leader>KK",
			function()
				require("diagram").show_diagram_hover()
			end,
			mode = "n",
			ft = { "markdown", "norg" },
			desc = "Show diagram in new tab",
		},
		{
			"<leader>KO",
			function()
				local bufnr = vim.api.nvim_get_current_buf()
				local row = vim.api.nvim_win_get_cursor(0)[1] - 1
				local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
				local diagrams = require("diagram.integrations.markdown").query_buffer_diagrams(bufnr)
				local diagram

				for _, candidate in ipairs(diagrams) do
					if candidate.renderer_id == "mermaid" then
						local start_row = candidate.range.start_row
						local end_row = candidate.range.end_row
						for i = start_row, 0, -1 do
							if lines[i + 1] and lines[i + 1]:match("^%s*```") then
								start_row = i
								break
							end
						end
						for i = end_row, #lines - 1 do
							if lines[i + 1] and lines[i + 1]:match("^%s*```%s*$") then
								end_row = i
								break
							end
						end
						if row >= start_row and row <= end_row then
							diagram = candidate
							break
						end
					end
				end

				if not diagram then
					vim.notify("No Mermaid diagram found at cursor", vim.log.levels.INFO)
					return
				end

				local result = require("diagram.renderers.mermaid").render(diagram.source, {
					background = "transparent",
					theme = "dark",
					scale = 4,
					width = 2400,
					height = 1800,
				})
				if not result then return end

				local open_image = function()
					if vim.fn.filereadable(result.file_path) == 1 then
						vim.ui.open(result.file_path)
					else
						vim.notify("High-quality Mermaid PNG was not created", vim.log.levels.ERROR)
					end
				end

				if not result.job_id then
					open_image()
					return
				end

				local timer = (vim.uv or vim.loop).new_timer()
				timer:start(0, 100, vim.schedule_wrap(function()
					if vim.fn.jobwait({ result.job_id }, 0)[1] == -1 then return end
					timer:stop()
					timer:close()
					open_image()
				end))
			end,
			mode = "n",
			ft = "markdown",
			desc = "Open Mermaid PNG in system viewer",
		},
	},
}
