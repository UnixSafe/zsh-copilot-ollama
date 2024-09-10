# ZSH Copilot Script for Ollama

(( ! ${+ZSH_COPILOT_KEY} )) &&
    typeset -g ZSH_COPILOT_KEY='^z'

(( ! ${+ZSH_COPILOT_SEND_CONTEXT} )) &&
    typeset -g ZSH_COPILOT_SEND_CONTEXT=true

(( ! ${+ZSH_COPILOT_DEBUG} )) &&
    typeset -g ZSH_COPILOT_DEBUG=false

(( ! ${+ZSH_COPILOT_OLLAMA_MODEL} )) &&
    typeset -g ZSH_COPILOT_OLLAMA_MODEL='llama3.1:8b'

read -r -d '' SYSTEM_PROMPT <<- EOM
You are a shell command assistant. Given the raw input of a shell command, your task is to:

1. Complete the command with relevant options or arguments, OR
2. Provide a new command that you think the user is trying to type.

Rules:
- If returning a completely new command, prefix it with an equal sign (=).
- If returning a completion for the user's command, prefix it with a plus sign (+).
- For completions, ONLY INCLUDE THE REST OF THE COMPLETION. Do not repeat what the user has already typed.
- Do not write any leading or trailing characters except if required for the completion to work.
- Your response MUST start with either a plus sign (+) or an equal sign (=), but NEVER both.
- You MAY explain the command by writing a short line after the comment symbol (#).
- Do not ask for more information; you won't receive it.
- Ensure the command or completion can run in the user's shell without modifications.
- Make sure to escape input correctly if needed.
- DO NOT RETURN ANYTHING OTHER THAN A SHELL COMMAND OR COMPLETION.
- DO NOT INTERACT WITH THE USER IN NATURAL LANGUAGE.

Examples:
User input: 'list files in current directory'
Your response: '=ls -la # List all files, including hidden ones, with details'

User input: 'cd /tm'
Your response: '+p # /tmp is the standard temp folder on Linux and macOS'

User input: 'grep "error" log'
Your response: '+ -i # Case-insensitive search'

Remember, your response will be directly used or executed in the shell, so ensure it's correct and safe.
EOM

if [[ "$OSTYPE" == "darwin"* ]]; then
    SYSTEM="Your system is ${$(sw_vers | xargs | sed 's/ /./g')}."
else 
    SYSTEM="Your system is ${$(cat /etc/*-release | xargs | sed 's/ /,/g')}."
fi

function _suggest_ai() {
    if [[ "$ZSH_COPILOT_SEND_CONTEXT" == 'true' ]]; then
        local PROMPT="$SYSTEM_PROMPT 
            Context: You are user $(whoami) with id $(id) in directory $(pwd). 
            Your shell is $(echo $SHELL) and your terminal is $(echo $TERM) running on $(uname -a).
            $SYSTEM"
    fi
    # Get input
    local input=$(echo "${BUFFER:0:$CURSOR}" | tr '\n' ';')
    input=$(echo "$input" | sed 's/"/\\"/g')

    _zsh_autosuggest_clear
    zle -R "Thinking..."

    PROMPT=$(echo "$PROMPT" | tr -d '\n')

    local data="{
            \"model\": \"$ZSH_COPILOT_OLLAMA_MODEL\",
            \"prompt\": \"$PROMPT\n\nUser: $input\",
            \"stream\": false
        }"
    local response=$(curl "http://localhost:11434/api/generate" \
        --silent \
        -H "Content-Type: application/json" \
        -d "$data")
    
    if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
        echo "Debug: Full response from Ollama: $response" >> /tmp/zsh-copilot.log
    fi

    if [[ -z "$response" ]]; then
        echo "Error: No response from Ollama. Is it running?" >&2
        return 1
    fi

    local message
    if command -v jq >/dev/null 2>&1; then
        message=$(echo "$response" | jq -r '.response // empty')
    else
        message=$(echo "$response" | grep -o '"response":"[^"]*' | sed 's/"response":"//;s/"$//')
    fi

    if [[ -z "$message" ]]; then
        echo "Error: Unable to extract response from Ollama output." >&2
        echo "Raw response: $response" >&2
        return 1
    fi

    # Nettoyage et validation de la réponse
    message=$(echo "$message" | sed "s/^[\"']//;s/[\"']$//;s/^[[:space:]]*//;s/[[:space:]]*$//")
    local first_char=${message:0:1}
    local suggestion=${message:1}

    if [[ "$first_char" != '+' && "$first_char" != '=' ]]; then
        # Si le format n'est pas respecté, on traite tout comme une nouvelle commande
        first_char='='
        suggestion=$message
    fi

    if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
        echo "Debug: Cleaned message: $message" >> /tmp/zsh-copilot.log
        echo "Debug: First char: $first_char" >> /tmp/zsh-copilot.log
        echo "Debug: Suggestion: $suggestion" >> /tmp/zsh-copilot.log
    fi

    if [[ "$first_char" == '=' ]]; then
        # Nouvelle commande : remplacer le buffer actuel
        BUFFER="$suggestion"
        CURSOR=${#BUFFER}
    elif [[ "$first_char" == '+' ]]; then
        # Complétion : utiliser zsh-autosuggestions
        local new_buffer="${BUFFER}${suggestion}"
        _zsh_autosuggest_suggest "$new_buffer"
    else
        echo "Error: Invalid response format from Ollama" >&2
        return 1
    fi
}

function zsh-copilot() {
    echo "ZSH Copilot is now active. Press $ZSH_COPILOT_KEY to get suggestions."
    echo ""
    echo "Configurations:"
    echo "    - ZSH_COPILOT_KEY: Key to press to get suggestions (default: ^z, value: $ZSH_COPILOT_KEY)."
    echo "    - ZSH_COPILOT_SEND_CONTEXT: If \`true\`, zsh-copilot will send context information (whoami, shell, pwd, etc.) to the AI model (default: true, value: $ZSH_COPILOT_SEND_CONTEXT)."
    echo "    - ZSH_COPILOT_OLLAMA_MODEL: The Ollama model to use (default: llama3.1:8b, value: $ZSH_COPILOT_OLLAMA_MODEL)."
}

zle -N _suggest_ai
bindkey $ZSH_COPILOT_KEY _suggest_ai
