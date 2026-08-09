{ lib, pkgs, ... }:
let
  primeAgent = pkgs.buildNpmPackage (finalAttrs: {
    pname = "prime-agent";
    version = "0.7.1";

    src = pkgs.fetchFromGitHub {
      owner = "PrimeIntellect-ai";
      repo = "prime-agent";
      tag = "v${finalAttrs.version}";
      hash = "sha256-0QheD6herrWiLxEugmQytSJ0yd48SY+k7uDHiS88AoA=";
      postFetch = ''
        ${lib.getExe pkgs.npm-lockfile-fix} "$out/package-lock.json"
      '';
    };

    npmDepsHash = "sha256-B+mwGIZ5lTr2/+lTAvyeJDtsIigPSnkMByIoJrxCq9Q=";
    npmDepsFetcherVersion = 2;
    npmWorkspace = "packages/coding-agent";
    npmRebuildFlags = [ "--ignore-scripts" ];

    buildPhase = ''
      runHook preBuild

      npx tsgo -p packages/ai/tsconfig.build.json
      npx tsgo -p packages/tui/tsconfig.build.json
      npx tsgo -p packages/agent/tsconfig.build.json
      npm run build --workspace=packages/coding-agent

      runHook postBuild
    '';

    postInstall = ''
      local nm="$out/lib/node_modules/prime-agent/node_modules"

      for ws in @earendil-works/pi-ai:packages/ai \
                @earendil-works/pi-agent-core:packages/agent \
                @earendil-works/pi-tui:packages/tui; do
        IFS=: read -r package source <<< "$ws"
        rm "$nm/$package"
        cp -r "$source" "$nm/$package"
      done

      find "$nm" -type l -lname '*/packages/*' -delete
      find "$nm/.bin" -xtype l -delete

      local cli="$out/lib/node_modules/prime-agent/dist/bundle/cli.js"
      substituteInPlace "$cli" \
        --replace-fail \
          'import { createRequire as __piBundleCreateRequire }' \
          'process.env.PATH = "${
            lib.makeBinPath [
              pkgs.fd
              pkgs.python311
              pkgs.ripgrep
              pkgs.uv
            ]
          }:" + (process.env.PATH ?? "");
          process.env.PI_SKIP_VERSION_CHECK ??= "1";
          process.env.PI_TELEMETRY ??= "0";
          import { createRequire as __piBundleCreateRequire }'

      rm "$out/bin/pi"
      ln -s ../lib/node_modules/prime-agent/dist/bundle/cli.js "$out/bin/prime-agent"
    '';

    doInstallCheck = true;
    nativeInstallCheckInputs = [
      pkgs.versionCheckHook
      pkgs.writableTmpDirAsHomeHook
    ];
    versionCheckKeepEnvironment = [ "HOME" ];
    versionCheckProgram = "${placeholder "out"}/bin/prime-agent";
    versionCheckProgramArg = "--version";

    meta = {
      description = "Self-improving RLM coding and research agent";
      homepage = "https://github.com/PrimeIntellect-ai/prime-agent";
      changelog = "https://github.com/PrimeIntellect-ai/prime-agent/blob/v${finalAttrs.version}/packages/coding-agent/CHANGELOG.md";
      license = lib.licenses.mit;
      mainProgram = "prime-agent";
    };
  });

  agentSandbox = pkgs.python3Packages.buildPythonApplication {
    pname = "agent-sandbox";
    version = "0.1.0-unstable-2026-08-06";
    pyproject = true;

    src = pkgs.fetchFromGitHub {
      owner = "anonx3247";
      repo = "agent-sandbox";
      rev = "705d8801356e758819dfbbe4fba7022fe96475f8";
      hash = "sha256-qjybxgqDw7s0UdnIwoMLvsmg4sOpcgDdEqZSuv/cfVc=";
    };

    build-system = [ pkgs.python3Packages.hatchling ];
    dependencies = [ pkgs.python3Packages.typer ];

    nativeCheckInputs = [ pkgs.python3Packages.pytestCheckHook ];

    meta = {
      description = "Sandbox wrapper for coding agents";
      homepage = "https://github.com/anonx3247/agent-sandbox";
      license = lib.licenses.mit;
      mainProgram = "asb";
    };
  };
in
{
  home.packages = [
    primeAgent
    agentSandbox
    pkgs.sandbox-runtime
    pkgs.bubblewrap
    pkgs.socat
  ];

  # Use `prime-agent` normally, or `agent` for the sandboxed git profile.
  home.shellAliases.agent = "asb -p git -- prime-agent";

  home.file = {
    ".local/bin/prime-agent" = {
      force = true;
      source = "${primeAgent}/bin/prime-agent";
    };
    ".prime/agent/AGENTS.md" = {
      force = true;
      source = ./pi/AGENTS.md;
    };
    ".prime/agent/settings.json" = {
      force = true;
      text = builtins.toJSON {
        onboardingShown = true;
        defaultProvider = "openai-codex";
        defaultModel = "gpt-5.6-sol";
        defaultThinkingLevel = "xhigh";
        recentModels = [ "openai-codex/gpt-5.6-sol" ];
        skills = [ "~/.pi/agent/skills" ];
      };
    };
  };
}
