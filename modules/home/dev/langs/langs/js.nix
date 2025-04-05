{ pkgs, ... }: {
  home.packages = with pkgs; [ typescript nodejs yarn bun nodePackages_latest.prisma prisma-engines ];
}
