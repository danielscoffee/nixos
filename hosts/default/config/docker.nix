{
  # Docker
  virtualisation.podman.enable = true;
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };
}
