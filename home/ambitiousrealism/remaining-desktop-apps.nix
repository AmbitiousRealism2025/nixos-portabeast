{ pkgs, ... }:

{
  # Native desktop application batch retained from the migration inventory.
  # Installation alone does not enable EasyEffects at login, pair Moonlight,
  # or import application data and accounts.
  home.packages = with pkgs; [
    easyeffects
    vlc
    obsidian
    moonlight-qt
  ];
}
