# devops-toolbox — AI Context

## Purpose

Reusable DevOps setup scripts, automation, environment configurations, and tool configs. This is a satellite repo of the [DevOps-LearnIT](https://github.com/ddeer1109/DevOps-LearnIT) hub — things that live beyond the bootcamp course.

## Structure

```
devops-toolbox/
├── wsl/              # WSL setup & configuration scripts
├── ubuntu-server/    # Ubuntu server provisioning
├── dotfiles/         # Shell configs, aliases, tool configs
├── scripts/          # Reusable automation scripts
└── mcp-servers/      # MCP server configs for Claude Code
```

## Conventions

- **Language**: All documentation in English
- **Scripts**: Include usage comments at the top of every script
- **Naming**: Kebab-case for files, UPPER_SNAKE for env vars
- **Secrets**: Never commit credentials — use `.gitignore` and `.env.example` patterns
- **Testing**: Test scripts in a VM/container before committing
