{
  lib,
  stdenvNoCC,
  fetchurl,
  makeBinaryWrapper,
  installShellFiles,
  ripgrep,
  bubblewrap,
}:
let
  sources = lib.importJSON ./sources.json;
  inherit (stdenvNoCC.hostPlatform) system;
  platform = sources.platforms.${system} or (throw "codex: no release binary for ${system}");
  # Release tarballs hold one static musl binary named <asset>-<target>.
  fetchAsset =
    asset:
    fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${sources.version}/${asset}-${platform.target}.tar.gz";
      hash = platform.${asset};
    };
in
stdenvNoCC.mkDerivation {
  pname = "codex";
  inherit (sources) version;

  srcs = [
    (fetchAsset "codex")
    (fetchAsset "codex-code-mode-host")
  ];
  sourceRoot = ".";

  nativeBuildInputs = [
    makeBinaryWrapper
    installShellFiles
  ];

  dontConfigure = true;
  dontBuild = true;

  # codex-code-mode-host must sit beside the codex binary.
  installPhase = ''
    runHook preInstall
    install -Dm755 codex-${platform.target} $out/bin/codex
    install -Dm755 codex-code-mode-host-${platform.target} $out/bin/codex-code-mode-host
    runHook postInstall
  '';

  postInstall = ''
    export HOME=$TMPDIR
    installShellCompletion --cmd codex \
      --bash <($out/bin/codex completion bash) \
      --fish <($out/bin/codex completion fish) \
      --zsh <($out/bin/codex completion zsh)
  '';

  # Same runtime PATH as nixpkgs' source build: rg for search, bwrap for the
  # Linux sandbox.
  postFixup = ''
    wrapProgram $out/bin/codex --prefix PATH : ${
      lib.makeBinPath [
        ripgrep
        bubblewrap
      ]
    }
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    HOME=$TMPDIR $out/bin/codex --version | grep -F ${lib.escapeShellArg sources.version}
    runHook postInstallCheck
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "OpenAI's lightweight coding agent that runs in your terminal";
    homepage = "https://github.com/openai/codex";
    changelog = "https://github.com/openai/codex/releases/tag/rust-v${sources.version}";
    license = lib.licenses.asl20;
    mainProgram = "codex";
    platforms = builtins.attrNames sources.platforms;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
