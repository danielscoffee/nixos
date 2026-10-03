# Pinned third-party agent skills shared by Pi and Claude Code.
{ pkgs }:
{
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
  frontendDesignSkill = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/anthropics/claude-code/45bdfa96ca415da92e62b6ca85a1d6e29adf3c44/plugins/frontend-design/skills/frontend-design/SKILL.md";
    hash = "sha256-Fgjqd/u2/DDROpfRLPqOvzE1jUDw3Ze+7SSCnWs/Rd0=";
  };
  frontendDesignLicense = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/anthropics/claude-code/45bdfa96ca415da92e62b6ca85a1d6e29adf3c44/LICENSE.md";
    hash = "sha256-coFY/RA3FD+taQfo+jSAQXflmLcyZRlQP+g8r974SeY=";
  };
}
