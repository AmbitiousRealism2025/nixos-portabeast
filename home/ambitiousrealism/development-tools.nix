{
  albion,
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
    albion
  ];

  # Claude Code is installed once inside the Albion package. The `claude` and
  # `albion` commands both launch Albion with ~/.claude-albion and load
  # ~/.albion/secrets.sh only for that invocation. `claude-stock` preserves an
  # explicit Anthropic fallback using ~/.claude; Claudex will later receive a
  # third configuration directory.
}
