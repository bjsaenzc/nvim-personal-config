-- Java LSP (eclipse.jdt.ls) via nvim-jdtls (P3-04).
-- jdtls needs a per-project setup, so the actual start lives in
-- ftplugin/java.lua (runs on every java buffer); this spec only ships the plugin.
-- jdtls itself is installed by Mason (see mason-tool-installer.lua) and
-- requires a Java 17+ runtime on PATH.
return {
  "mfussenegger/nvim-jdtls",
  ft = "java",
}
