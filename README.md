# zsh-copilot

Get AI-powered suggestions directly in your shell using Ollama. No need for external "suggest" commands. Simply press `CTRL + Z` to receive intelligent completions and suggestions.

## Features

- Seamless integration with your ZSH shell
- Uses locally-run Ollama models for suggestions
- Supports command completions and new command suggestions
- Customizable key binding and model selection

## Installation

### Dependencies

Please ensure you have the following dependencies installed:

* [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
* [jq](https://github.com/jqlang/jq)
* [curl](https://github.com/curl/curl)
* [Ollama](https://github.com/jmorganca/ollama)

### Setup

1. Clone the repository:
   ```sh
   git clone https://github.com/YourUsername/zsh-copilot.git ~/.zsh-copilot
   ```

2. Add the following line to your `~/.zshrc`:
   ```sh
   source ~/.zsh-copilot/zsh-copilot.plugin.zsh
   ```

3. Reload your ZSH configuration:
   ```sh
   source ~/.zshrc
   ```

## Configuration

You can customize zsh-copilot by setting the following environment variables in your `~/.zshrc`:

```sh
export ZSH_COPILOT_KEY='^z'  # Key to trigger suggestions (default: Ctrl+Z)
export ZSH_COPILOT_OLLAMA_MODEL='llama3.1:8b'  # Ollama model to use
export ZSH_COPILOT_SEND_CONTEXT=true  # Send shell context to the model
export ZSH_COPILOT_DEBUG=false  # Enable debug mode
```

To see available configurations, run:
```sh
zsh-copilot
```

## Usage

1. Start typing a command or describe what you want to do.
2. Press `CTRL + Z` (or your custom key binding) to get a suggestion.
3. The suggestion will either complete your current command or propose a new one.

## Examples

- Type `list all file` and press `CTRL + Z` to get `ls -la`
- Start with `grep 'warning'` and press `CTRL + Z` to get additional options like `-rn`

## Troubleshooting

If you encounter issues:

1. Ensure Ollama is running and the specified model is available.
2. Check the `/tmp/zsh-copilot.log` file if debug mode is enabled.
3. Verify that all dependencies are correctly installed.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.


