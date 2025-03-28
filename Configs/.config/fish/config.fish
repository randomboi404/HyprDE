set fish_greeting
set VIRTUAL_ENV_DISABLE_PROMPT "1"
set -xU MANPAGER "sh -c 'col -bx | bat -l man -p'"
set -xU MANROFFOPT "-c"
set -x SHELL /usr/bin/fish


source ~/.config/fish/hyde_config.fish

if status is-interactive
    # Commands to run in interactive sessions can go here
end

## Starship prompt
if status --is-interactive
   source ("/usr/bin/starship" init fish --print-full-init | psub)
end

pokemon-colorscripts --no-title -s -r

# Replace ls with eza
alias ls 'eza -al --color=always --group-directories-first --icons' # preferred listing
alias la 'eza -a --color=always --group-directories-first --icons'  # all files and dirs
alias ll 'eza -l --color=always --group-directories-first --icons'  # long format
alias lt 'eza -aT --color=always --group-directories-first --icons' # tree listing
alias l. 'eza -ald --color=always --group-directories-first --icons .*' # show only dotfiles

# Common use
alias .. 'cd ..'
alias ... 'cd ../..'
alias .... 'cd ../../..'
alias ..... 'cd ../../../..'
alias ...... 'cd ../../../../..'
alias wget 'wget -c '

alias google-chrome-stable="google-chrome-stable --enable-features=UseOzonePlatform --ozone-platform=wayland"
alias obsidian="obsidian --enable-features=UseOzonePlatform --ozone-platform=wayland"

# Always mkdir a path (this doesn't inhibit functionality to make a single dir)
abbr mkdir 'mkdir -p'

alias backup="cd ~/dotfiles && git add . && git commit -m \"Backup: $(date "+%Y-%m-%d %T")\" && git push"
alias update-grub="sudo grub-mkconfig -o /boot/grub/grub.cfg"

alias spotx-flatpak="fish <(curl -sSL https://raw.githubusercontent.com/Nuzair46/BlockTheSpot-Linux/main/install.sh) -P /var/lib/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify/ -h";

zoxide init fish --cmd cd | source
