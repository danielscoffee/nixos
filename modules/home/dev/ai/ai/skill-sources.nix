# Pinned third-party agent skills shared by Pi, Claude Code and Codex.
{ pkgs }:
let
  # nixpkgs' graphify re-execs `sys.executable -m graphify`, which fails from
  # the bare-interpreter wrapper; the env wrapper points sys.executable here.
  graphifyPython = pkgs.python3.withPackages (ps: [ (ps.toPythonModule pkgs.graphify) ]);
in
{
  graphifyCli = pkgs.runCommandLocal "graphify-cli-${pkgs.graphify.version}" { } ''
    mkdir -p $out/bin
    ln -s ${graphifyPython}/bin/graphify $out/bin/graphify
  '';
  tasteSkills = pkgs.fetchFromGitHub {
    owner = "Leonxlnx";
    repo = "taste-skill";
    rev = "72e299530e2eb31ed8da06181bc19f6c18a00821";
    hash = "sha256-DH1Q+1FgcVHnxMuXwifutCtTXulJjDgzwmQ9kSbL0a8=";
  };
  vercelAgentSkills = pkgs.fetchFromGitHub {
    owner = "vercel-labs";
    repo = "agent-skills";
    rev = "dd089a8c752c966dee8bf0f27cb625ba193ffd9e";
    hash = "sha256-fXbWS0+jtRYXdVn1KdqBdU0wEirrg5t/3IxdqPaAs8M=";
  };
  playwrightCliSource = pkgs.fetchFromGitHub {
    owner = "microsoft";
    repo = "playwright-cli";
    rev = "2f85a94b7b885dbf4a5d34462f253a8746a690c9";
    hash = "sha256-KH2rl0uS/zFPebjmg6MZndcl6Llx4c9/yfCGvisBn7g=";
  };
  emilSkills = pkgs.fetchFromGitHub {
    owner = "emilkowalski";
    repo = "skills";
    rev = "e8a175de22ae1e49370fc144c1f3bb9aeedf988d";
    hash = "sha256-FG1zm/Vr00QAvpSA6uuVbPJrOjFj2W+F1SAChlJOGMk=";
  };
  frontendDesignSkill = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/anthropics/claude-code/45bdfa96ca415da92e62b6ca85a1d6e29adf3c44/plugins/frontend-design/skills/frontend-design/SKILL.md";
    hash = "sha256-Fgjqd/u2/DDROpfRLPqOvzE1jUDw3Ze+7SSCnWs/Rd0=";
  };
  frontendDesignLicense = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/anthropics/claude-code/45bdfa96ca415da92e62b6ca85a1d6e29adf3c44/LICENSE.md";
    hash = "sha256-coFY/RA3FD+taQfo+jSAQXflmLcyZRlQP+g8r974SeY=";
  };
  # Graphify's per-agent skill bundles (SKILL.md + references/), laid out as
  # <agent>/ for claude, codex and pi. Upstream's interpreter probe can't see
  # through the Nix bash wrapper and falls back to `pip`/`uv tool install`,
  # so pin it to graphifyPython. No .graphify_version stamp: without it the
  # CLI never rewrites these copies.
  graphifySkills =
    let
      share = "${pkgs.graphify}/${pkgs.python3.sitePackages}/graphify";
    in
    pkgs.runCommandLocal "graphify-skills-${pkgs.graphify.version}" { } ''
      for agent in claude codex pi; do
        case $agent in
          claude) skill=skill.md ;;
          *) skill=skill-$agent.md ;;
        esac
        install -Dm644 ${share}/$skill $out/$agent/SKILL.md
        cp -r ${share}/skills/$agent/references $out/$agent/references
        substituteInPlace $out/$agent/SKILL.md \
          --replace-fail 'PYTHON=""' 'PYTHON="${graphifyPython.interpreter}"' \
          --replace-fail 'PYTHON="python3"' 'PYTHON="${graphifyPython.interpreter}"'
      done
    '';
}
