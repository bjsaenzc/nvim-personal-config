-- Start (or attach to) jdtls for this Java buffer (P3-04).
-- Each project gets its own workspace dir so indexes never bleed across projects.

local ok, jdtls = pcall(require, "jdtls")
if not ok then
  return -- plugin not installed yet (first sync)
end

local root = vim.fs.root(0, { "gradlew", "mvnw", "pom.xml", "build.gradle", ".git" })
if not root then
  return -- scratch/single files: skip jdtls rather than index $HOME
end

-- Unique, stable workspace per project: name + short hash of the full path
local project_name = vim.fn.fnamemodify(root, ":p:h:t")
local workspace = vim.fn.stdpath("data")
  .. "/jdtls-workspaces/"
  .. project_name .. "-" .. vim.fn.sha256(root):sub(1, 8)

jdtls.start_or_attach({
  cmd = {
    vim.fn.stdpath("data") .. "/mason/bin/jdtls",
    "-data", workspace,
  },
  root_dir = root,
  settings = {
    java = {},
  },
})
