{
  claudeCode,
  pkgs,
  ...
}:

{
  # Use the current LTS JDK as the interactive default. Individual projects
  # can still select another Java release through their own flake or mise.
  home.sessionVariables.JAVA_HOME = pkgs.jdk25.home;

  home.packages = [
    pkgs.jdk25
    pkgs.zed-editor
    claudeCode
  ];

  # Claude Code is installed once. Claudex and Albion will later receive
  # separate CLAUDE_CONFIG_DIR values so credentials, settings, history, and
  # plugins cannot collide; no provider configuration belongs in this layer.
}
