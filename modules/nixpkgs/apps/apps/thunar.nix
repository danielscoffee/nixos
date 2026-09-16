{ lib, pkgs, ... }:
{
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
    ];
  };
  services.gvfs.enable = true;

  environment.systemPackages = [ pkgs.kdePackages.ark ];

  xdg.mime.defaultApplications = lib.genAttrs [
    "application/zip"
    "application/x-7z-compressed"
    "application/vnd.rar"
    "application/x-tar"
    "application/x-compressed-tar"
    "application/x-bzip-compressed-tar"
    "application/x-bzip2-compressed-tar"
    "application/x-xz-compressed-tar"
    "application/x-zstd-compressed-tar"
    "application/gzip"
    "application/x-bzip"
    "application/x-bzip2"
    "application/x-xz"
    "application/zstd"
  ] (_: "org.kde.ark.desktop");
}
