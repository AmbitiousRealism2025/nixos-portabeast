{
  albion,
  claudex,
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
    claudex
  ];

  # Claude Code is installed once inside the Albion package. The `claude` and
  # `albion` commands both launch Albion with ~/.claude-albion and load
  # ~/.albion/secrets.sh only for that invocation. `claude-stock` preserves an
  # explicit Anthropic fallback using ~/.claude. `claudex` uses the same
  # signed Claude binary through a private PATH, an isolated
  # ~/.config/claudex profile, and the pinned loopback-only ProxyCLI bridge.
}
