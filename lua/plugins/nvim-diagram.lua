-- diagram.nvim keys its renderer caches only by source text. Without this
-- discriminator, an image rendered before a renderer-option change is reused
-- indefinitely, so changes to scale/size/theme appear to do nothing. The hash is
-- appended to the source as a comment in the diagram's own language.
local function key_cache_by_options(renderer_id, comment)
	local renderer = require("diagram.renderers." .. renderer_id)
	local render = renderer.render
	renderer.render = function(source, renderer_opts)
		-- Copied because the D2 renderer writes its default format back into the
		-- table, which would change the hash between the first and second render.
		renderer_opts = vim.deepcopy(renderer_opts or {})
		local options_hash = vim.fn.sha256(vim.inspect(renderer_opts))
		return render(source .. "\n" .. comment .. " diagram-render-options: " .. options_hash, renderer_opts)
	end
end

-- High-quality, light-themed PNG settings for <leader>KO, keyed by renderer id.
local viewer_options = {
	mermaid = {
		background = "transparent",
		theme = "neutral",
		scale = 4,
		width = 2400,
		height = 1800,
	},
	d2 = {
		theme_id = 0, -- Neutral Default
		scale = 2, -- on top of D2's built-in 2x PNG device scale
	},
}

local viewer_labels = { mermaid = "Mermaid", d2 = "D2" }

return {
	"3rd/diagram.nvim",
	ft = "markdown",
	dependencies = {
		{
			"3rd/image.nvim",
		},
	},
	config = function(_, opts)
		key_cache_by_options("mermaid", "%%")
		key_cache_by_options("d2", "#")

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
			d2 = {
				theme_id = 200, -- Dark Mauve
				-- D2 already exports PNGs at a 2x device scale, so 1 here is the
				-- counterpart of Mermaid's scale = 2. dark_theme_id is SVG-only.
				scale = 1,
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
					if viewer_options[candidate.renderer_id] then
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
					vim.notify("No Mermaid or D2 diagram found at cursor", vim.log.levels.INFO)
					return
				end

				local renderer_id = diagram.renderer_id
				local renderer = require("diagram.renderers." .. renderer_id)
				local result = renderer.render(diagram.source, viewer_options[renderer_id])
				if not result then
					return
				end

				local open_image = function()
					if vim.fn.filereadable(result.file_path) == 1 then
						vim.ui.open(result.file_path)
					else
						vim.notify("High-quality " .. viewer_labels[renderer_id] .. " PNG was not created", vim.log.levels.ERROR)
					end
				end

				if not result.job_id then
					open_image()
					return
				end

				local timer = (vim.uv or vim.loop).new_timer()
				timer:start(
					0,
					100,
					vim.schedule_wrap(function()
						if vim.fn.jobwait({ result.job_id }, 0)[1] == -1 then
							return
						end
						timer:stop()
						timer:close()
						open_image()
					end)
				)
			end,
			mode = "n",
			ft = "markdown",
			desc = "Open Mermaid/D2 PNG in system viewer",
		},
	},
}
