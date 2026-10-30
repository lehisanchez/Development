# =========================================================
# RUBY ON RAILS BASELINE APPLICATION TEMPLATE
# Author: Lehi Sanchez
# Updated: 2026-10-30
# =========================================================

# ---------------------------------------------------------
# Agentic Coding
# ---------------------------------------------------------

get "https://github.com/lehisanchez/Development/raw/refs/heads/main/Rails/Agents/AGENTS.md", "AGENTS.md"
get "https://github.com/lehisanchez/Development/raw/refs/heads/main/Rails/Agents/STYLE.md", "STYLE.md"

empty_directory ".claude"

create_file ".claude/CLAUDE.md" do
  "@../AGENTS.md"
end


# ---------------------------------------------------------
# Devcontainer
# Add extra features to devcontainer.json
# (only when the app was generated with --devcontainer)
# ---------------------------------------------------------
devcontainer_settings = ".devcontainer/devcontainer.json"
devcontainer_features = [
  "ghcr.io/devcontainers/features/node:2",
  "ghcr.io/anthropics/devcontainer-features/claude-code:1.0"
]

if File.exist?(File.join(destination_root, devcontainer_settings))
  existing = File.read(File.join(destination_root, devcontainer_settings))
  missing = devcontainer_features.reject { |feature| existing.include?(%("#{feature}")) }

  if missing.any?
    new_lines = missing.map { |feature| %(    "#{feature}": {}) }.join(",\n")

    # Append after the last generated feature, before the block's closing brace
    gsub_file devcontainer_settings, /("features": \{\n.*?)\n  \}/m, "\\1,\n#{new_lines}\n  }"
  end

  # Point Claude Code at the mounted config dir
  claude_env = %("CLAUDE_CONFIG_DIR": "/home/vscode/.claude")

  unless existing.include?(claude_env)
    if existing.include?(%("containerEnv": {))
      # Append after the last generated variable, before the block's closing brace
      gsub_file devcontainer_settings, /("containerEnv": \{\n.*?)\n  \}/m, "\\1,\n    #{claude_env}\n  }"
    else
      # Rails omits containerEnv when it has no variables to set
      inject_into_file devcontainer_settings, <<~JSON.indent(2), before: "  // Use 'forwardPorts'"
        "containerEnv": {
          #{claude_env}
        },

      JSON
    end
  end

  # Give the vscode user ownership of the Claude config dir before setup
  gsub_file devcontainer_settings,
    %("postCreateCommand": "bin/setup --skip-server"),
    %("postCreateCommand": "sudo chown -R vscode:vscode /home/vscode/.claude && bin/setup --skip-server && claude install")

  # Persist the Claude config dir in a named volume
  claude_mount = %("source=claude-code-config,target=/home/vscode/.claude,type=volume")

  unless existing.include?(claude_mount)
    if existing.include?(%("mounts": [))
      # Rails only generates mounts with --dev; add ours to the front of that list
      inject_into_file devcontainer_settings, "\n    #{claude_mount},", after: %("mounts": [)
    else
      inject_into_file devcontainer_settings, <<~JSON.indent(2), before: "  // Use 'postCreateCommand'"
        "mounts": [
          #{claude_mount}
        ],

      JSON
    end
  end
end
