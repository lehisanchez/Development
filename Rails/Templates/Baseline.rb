# =========================================================
# RUBY ON RAILS BASELINE APPLICATION TEMPLATE
# Author: Lehi Sanchez
# Updated: 2026-10-30
# =========================================================

# ---------------------------------------------------------
# Agentic Coding
# ---------------------------------------------------------
empty_directory ".claude"

create_file ".claude/CLAUDE.md" do
  "@../AGENTS.md"
end

get "https://github.com/lehisanchez/Development/raw/refs/heads/main/Rails/Agents/AGENTS.md", "AGENTS.md"
get "https://github.com/lehisanchez/Development/raw/refs/heads/main/Rails/Agents/STYLE.md", "STYLE.md"
get "https://github.com/lehisanchez/Development/raw/refs/heads/main/Rails/Agents/Claude/settings.json", ".claude/settings.json"

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

# ---------------------------------------------------------
# GEMFILE
# ---------------------------------------------------------
remove_file "Gemfile"
get "https://github.com/lehisanchez/Development/raw/refs/heads/main/Rails/Templates/Gemfile", "Gemfile"

# ---------------------------------------------------------
# SimpleCov
# ---------------------------------------------------------
prepend_to_file "test/test_helper.rb" do
  "require \"simplecov\"\nSimpleCov.start \"rails\"\n\n"
end

# ---------------------------------------------------------
# GIT
# ---------------------------------------------------------
append_file '.gitignore', "# Ignore hidden system files\n.DS_Store\nThumbs.db\n"
append_file '.gitignore', "# Ignore SimpleCov files\ncoverage\n"

# ---------------------------------------------------------
# ENVIRONMENT
# ---------------------------------------------------------
environment <<-CODE.strip_heredoc
  # Enable UUIDs for primary keys
  config.generators do |g|
    g.orm :active_record, primary_key_type: :uuid
  end

  CODE

# ---------------------------------------------------------
# config/initializers/enable_yjit.rb
# ---------------------------------------------------------
initializer 'enable_yjit.rb', <<-CODE.strip_heredoc
  if defined? RubyVM::YJIT.enable
    Rails.application.config.after_initialize do
      RubyVM::YJIT.enable
    end
  end
  CODE

# ---------------------------------------------------------
# STATIC PAGES
# ---------------------------------------------------------
def install_static_pages
  rails_command("generate controller Pages welcome dashboard --skip-routes")

  inject_into_file "app/controllers/pages_controller.rb", after: "class PagesController < ApplicationController" do
    "\n  allow_unauthenticated_access only: %i[ welcome ]"
  end

  remove_file('app/views/pages/welcome.html.erb')

  file 'app/views/pages/welcome.html.erb' do
    <<-CODE.strip_heredoc
    <%= render "components/header" do %>
      <%= render "components/sidebar/trigger" %>
      <%= render "components/separator", orientation: :vertical %>
      <h1 class="text-sm font-medium">#{app_name.capitalize}</h1>
    <% end %>
    CODE
  end

  route 'get "dashboard", to: "pages#dashboard"'
  route 'root to: "pages#welcome"'
end

# ---------------------------------------------------------
# AFTER BUNDLE
# ---------------------------------------------------------
after_bundle do
  rails_command("generate rails_live_reload:install")
  rails_command("generate sqlite_crypto:install")
  rails_command("generate maquina_components:install")
  rails_command("generate authentication")
  install_static_pages
  run("bundle exec bin/setup --skip-server")
  run("bundle exec bin/ci")
  git add: "."
  git commit: "-a -m 'Initial commit'"
  run("code .")
end
