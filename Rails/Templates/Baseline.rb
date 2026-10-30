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

create_file ".claude/settings.json" do <<-CODE.strip_heredoc
  {
    "extraKnownMarketplaces": {
      "caveman": {
        "source": {
          "source": "github",
          "repo": "JuliusBrussee/caveman"
        }
      },
      "maquina": {
        "source": {
          "source": "github",
          "repo": "maquina-app/rails-claude-code"
        }
      }
    },
    "enabledPlugins": {
      "caveman@caveman": true,
      "better-stimulus@maquina": true,
      "hotwire-patterns@maquina": true,
      "maquina-ui-standards@maquina": true,
      "mvp-creator@maquina": true,
      "rails-hotwire-driver@maquina": true,
      "rails-security-auditor@maquina": true,
      "rails-simplifier@maquina": true,
      "rails-upgrade-assistant@maquina": true,
      "spec-driven-development@maquina": true
    }
  }
  CODE
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
end


# ---------------------------------------------------------
# Devcontainer Compose
# Persist the Claude config dir in a named volume
# (only when the app was generated with --devcontainer)
# ---------------------------------------------------------
devcontainer_compose = ".devcontainer/compose.yaml"
claude_volume = "claude-code-config"

if File.exist?(File.join(destination_root, devcontainer_compose))
  existing = File.read(File.join(destination_root, devcontainer_compose))

  unless existing.include?("#{claude_volume}:/home/vscode/.claude")
    # Mount after the workspace volume in the rails-app service
    inject_into_file devcontainer_compose, "    - #{claude_volume}:/home/vscode/.claude\n",
      after: %r{^    volumes:\n    - \.\./\.\..*:cached\n}
  end

  unless existing.match?(/^  #{claude_volume}:$/)
    if existing.match?(/^volumes:$/)
      # Rails adds a top-level volumes block for database services; add ours to it
      inject_into_file devcontainer_compose, "\n  #{claude_volume}:\n    name: #{claude_volume}", after: /^volumes:$/
    else
      append_to_file devcontainer_compose, <<~YAML

        volumes:
          #{claude_volume}:
            name: #{claude_volume}
      YAML
    end
  end
end
