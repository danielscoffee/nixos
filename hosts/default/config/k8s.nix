{ pkgs, ... }:
#let
{
  environment.systemPackages = with pkgs; [ kompose kubectl kubernetes ];
}
