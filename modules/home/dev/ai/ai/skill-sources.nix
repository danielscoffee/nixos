# Pinned third-party agent skills shared by Pi, Claude Code and Codex.
{ pkgs }:
let
  # nixpkgs' graphify re-execs `sys.executable -m graphify`, which fails from
  # the bare-interpreter wrapper; the env wrapper points sys.executable here.
  graphifyPython = pkgs.python3.withPackages (ps: [ (ps.toPythonModule pkgs.graphify) ]);
in
{
  # Local skills in ./pi/skills that Claude Code and Codex share with Pi:
  # vendored (and partly patched) copies of github:mattpocock/skills, plus
  # nix-managed-debugging. code-review stays Pi-only: it collides with Claude
  # Code's built-in /code-review.
  localSkills = [
    "domain-modeling"
    "grill-me"
    "nix-managed-debugging"
    "teach"
    "wizard"
    "writing-for-agents"
  ];
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
  securityAuditSkill = pkgs.fetchFromGitHub {
    owner = "cloudflare";
    repo = "security-audit-skill";
    rev = "c1c8a8c1471069fb0e188eeaff69b8e8db6564a8";
    hash = "sha256-oVVACjotkHvllQGxEP8yWaEt4c3GxT0d909TUM5P3NM=";
  };
  # Ponytail's skills without its always-on hooks (Pi loads the full npm
  # package instead). `ponytail` itself becomes invoke-only, since its
  # description triggers on any coding task.
  ponytailSkills =
    let
      src = pkgs.fetchFromGitHub {
        owner = "DietrichGebert";
        repo = "ponytail";
        rev = "9b58c1ffb790c075ca32e70a89cf1d80588f4abf";
        hash = "sha256-S2gHV4/c8XPDqpf0jS8Q5r22//6skZjITf2T9CVhVRE=";
      };
    in
    pkgs.runCommandLocal "ponytail-skills" { } ''
      mkdir -p $out
      for s in ponytail ponytail-audit ponytail-debt; do
        cp -r ${src}/skills/$s $out/$s
      done
      chmod -R u+w $out
      skill=$out/ponytail/SKILL.md
      if [ "$(head -1 $skill)" != "---" ]; then
        echo "ponytail: SKILL.md no longer starts with frontmatter" >&2
        exit 1
      fi
      sed -i '1a disable-model-invocation: true' $skill
      install -Dm644 /dev/stdin $out/ponytail/agents/openai.yaml <<'EOF'
      policy:
        allow_implicit_invocation: false
      EOF
    '';
  # One skill from github:github/awesome-copilot; the repo is too big to
  # fetch whole.
  createReadmeSkill =
    let
      base = "https://raw.githubusercontent.com/github/awesome-copilot/82701c24b99488536ca399ff4789a458b7a05db7";
      skill = pkgs.fetchurl {
        url = "${base}/skills/create-readme/SKILL.md";
        hash = "sha256-qT+RYb7zJOOhVQ/HnU8BtmCj+36txEVWd9ms5NopZaw=";
      };
      license = pkgs.fetchurl {
        url = "${base}/LICENSE";
        hash = "sha256-4yRJ0jCFOZrcEiL3oXQItzBVAljlFifBU8sQjKmVWCM=";
      };
    in
    pkgs.runCommandLocal "create-readme-skill" { } ''
      install -Dm644 ${skill} $out/SKILL.md
      install -Dm644 ${license} $out/LICENSE
    '';
  # seoskill.dev; matches the pinned CLI in pkgs/seo (0.2.41).
  seoSource = pkgs.fetchFromGitHub {
    owner = "iannuttall";
    repo = "seo";
    rev = "5b794fe9c8addbc227c49262bb6ac79ad8429452";
    hash = "sha256-6eIpiHd1hHP5GfS7BRyKrz5Y17FQr+j9wICG9dzoOts=";
  };
  # PolyForm Noncommercial 1.0.0.
  onetakeSkill = pkgs.fetchFromGitHub {
    owner = "feitangyuan";
    repo = "onetake";
    rev = "2f5fbd363a0aec22055fbf62489380065737c91d";
    hash = "sha256-fna4JwnWik9A6gsnTjN5CWifkOgEeMLbdpTf7r9cE58=";
  };
  stopSlopSkill = pkgs.fetchFromGitHub {
    owner = "hardikpandya";
    repo = "stop-slop";
    rev = "8da1f030185bdfe8471220585162991eaeb970e9";
    hash = "sha256-JMqlCRVEAfwG1TLMDpnamznkBfkmX6e2XyETTTH/TSE=";
  };
  transitionsDevSource = pkgs.fetchFromGitHub {
    owner = "Jakubantalik";
    repo = "transitions.dev";
    rev = "2773886681b6bb8effe0d7b5c66306430d18e000";
    hash = "sha256-m+Hz7wBKm0IdcxFDfO0nfBV0yR+kUl88cpnM8eRbucM=";
  };
  # Only SKILL.md + LICENSE: the repo root also carries .claude-plugin/,
  # which would make Claude Code load the folder as a plugin.
  humanizerSkill =
    let
      src = pkgs.fetchFromGitHub {
        owner = "blader";
        repo = "humanizer";
        rev = "225a6f39ac85f76ee48dbad772ea4abe4ed6c9d8";
        hash = "sha256-n8cbTzhlGf8VnWpPukq7XD2mucIrqyE1XMpAAc5oA8A=";
      };
    in
    pkgs.runCommandLocal "humanizer-skill" { } ''
      install -Dm644 ${src}/SKILL.md $out/SKILL.md
      install -Dm644 ${src}/LICENSE $out/LICENSE
    '';
  # The skill's launcher runs a bundled engine before trying ~/.impeccable
  # or a network download, so ship the pinned static release binary there.
  impeccableSkill =
    let
      src = pkgs.fetchFromGitHub {
        owner = "pbakaus";
        repo = "impeccable";
        rev = "d631a8827f99414d2b6daba4ef08b7f8701751d7";
        hash = "sha256-0QpNzNnSon34/VVPPaitnSTBjpu9qJGXJzCJctS4gM0=";
      };
      engineVersion = "0.1.14";
      engines = {
        x86_64-linux = {
          arch = "linux-x64";
          hash = "sha256-PTHsGmZKw1yBXqHXwQq60RVc42TQ9GEVfrg3o0No77Y=";
        };
        aarch64-linux = {
          arch = "linux-arm64";
          hash = "sha256-OWJj7mlHgNuUJIP8gJM6AS7wi/mB9fJrDaXha2IIyUg=";
        };
      };
      engine = engines.${pkgs.stdenv.hostPlatform.system} or null;
      engineBin =
        if engine == null then
          null
        else
          pkgs.fetchurl {
            url = "https://github.com/pbakaus/impeccable/releases/download/engine-v${engineVersion}/impeccable-${engine.arch}";
            inherit (engine) hash;
          };
    in
    pkgs.runCommandLocal "impeccable-skill" { } (
      ''
        cp -r ${src}/.claude/skills/impeccable $out
        chmod -R u+w $out
        if [ "$(tr -d '[:space:]' < $out/scripts/VERSION)" != ${engineVersion} ]; then
          echo "impeccable: skill expects engine $(cat $out/scripts/VERSION), pinned ${engineVersion}" >&2
          exit 1
        fi
      ''
      + pkgs.lib.optionalString (engineBin != null) ''
        install -Dm755 ${engineBin} $out/scripts/bin/${engine.arch}/impeccable
      ''
    );
  # Upstream ships this as a plugin and resolves its search tool through
  # $CLAUDE_PLUGIN_ROOT; as a plain skill, point those paths at the skill
  # itself. Its test suite stays out.
  uiUxProMaxSkill =
    let
      src = pkgs.fetchFromGitHub {
        owner = "nextlevelbuilder";
        repo = "ui-ux-pro-max-skill";
        rev = "50d8a7de0900119855614541f15a1a616691eb33";
        hash = "sha256-P8bBIg+uhRDsG7ScrXNlbMNaoCn4t5S25fUJ02V14p8=";
      };
    in
    pkgs.runCommandLocal "ui-ux-pro-max-skill" { } ''
      cp -r ${src}/.claude/skills/ui-ux-pro-max $out
      chmod -R u+w $out
      rm -r $out/scripts/tests
      substituteInPlace $out/SKILL.md \
        --replace-fail '"''${CLAUDE_PLUGIN_ROOT}/.claude/skills/ui-ux-pro-max/' "\"$out/"
    '';
  # UI/motion packs for Claude Code, installed invoke-only and reached
  # through the high-end-frontend skill.
  gsapSkills = pkgs.fetchFromGitHub {
    owner = "greensock";
    repo = "gsap-skills";
    rev = "aed9cfd3277740755f6bfc1155c7aa645403b760";
    hash = "sha256-dAjDpjKP16Lw7sFjfaH6UjWy+2y9hPVLCO9CEaaZni4=";
  };
  # README says MIT, but the repo ships no LICENSE file.
  threejsSkills = pkgs.fetchFromGitHub {
    owner = "CloudAI-X";
    repo = "threejs-skills";
    rev = "b1c623076c661fc9b03dac19292e825a5d106823";
    hash = "sha256-jJ+n7UrmNtwO/ibbtUPx5k//UyJo5MwRrRq116AXomQ=";
  };
  genjutsuSource = pkgs.fetchFromGitHub {
    owner = "AThevon";
    repo = "genjutsu";
    rev = "1f518a71378b15d423389e546e767cffc86e14c3";
    hash = "sha256-eUCaH1iatE4y2+JNafdti1kH3VBjJ2cqiOkYRdiuS/o=";
  };
  motionDesignSource = pkgs.fetchFromGitHub {
    owner = "LottieFiles";
    repo = "motion-design-skill";
    rev = "f9a8a041b85185ee4881b3471d3415e939aac772";
    hash = "sha256-JVLvj10HmXuF9ja85BRA8+XPJ/2T4biFmH9VepNUdOQ=";
  };
  # The repo root is the skill; keep what SKILL.md loads and drop the
  # translated READMEs and tests.
  designDnaSkill =
    let
      src = pkgs.fetchFromGitHub {
        owner = "zanwei";
        repo = "design-dna";
        rev = "593e39bc9e3652734653bd75544a333d7d43615e";
        hash = "sha256-3TlZhr5m+4rHgX/fzD7X9Z1Y552+VuY5MJOCfpip5gE=";
      };
    in
    pkgs.runCommandLocal "design-dna-skill" { } ''
      mkdir -p $out
      cp -r ${src}/SKILL.md ${src}/LICENSE ${src}/references ${src}/scripts $out/
      chmod -R u+w $out
      rm -r $out/scripts/test
    '';
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
