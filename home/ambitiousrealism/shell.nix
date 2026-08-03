{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      g = "git";
      gcm = "git commit -m";
      gcam = "git commit -a -m";
      gcad = "git commit -a --amend";
      t = "tmux attach || tmux new -s Work";
    };
    initContent = ''
      export BAT_THEME=ansi

      open() {
        command xdg-open "$@" >/dev/null 2>&1 &
      }
    '';
  };

  programs.git = {
    enable = true;
    settings.init.defaultBranch = "main";
  };
  programs.gh.enable = true;
  programs.tmux.enable = true;
  programs.bat = {
    enable = true;
    config.theme = "ansi";
  };
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
  };

  home.packages = [ pkgs.xdg-utils ];
}
