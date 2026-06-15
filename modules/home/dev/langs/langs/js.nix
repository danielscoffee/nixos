{ pkgs, ... }: {
  home.packages = with pkgs; [ typescript nodejs yarn bun prisma prisma-engines ];
}
