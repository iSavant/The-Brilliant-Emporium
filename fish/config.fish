source /usr/share/cachyos-fish-config/cachyos-config.fish

if status is-interactive
    alias ls 'eza --icons --group-directories-first'
    alias ll 'eza -l --icons --git --group-directories-first'
    alias la 'eza -la --icons --git --group-directories-first'
    alias lt 'eza --tree --level=2 --icons --group-directories-first'
    alias cat 'bat --paging=never'

    zoxide init fish --cmd cd | source
    starship init fish | source
end

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

# Hermes Agent command
fish_add_path "$HOME/.local/bin"
