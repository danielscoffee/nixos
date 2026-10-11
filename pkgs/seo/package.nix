# seo (seoskill.dev) CLI, pinned. npm publishes it without a lockfile, so
# package-lock.json here was generated once with
# `npm install --package-lock-only --ignore-scripts`; regenerate it with the
# version bump in package.json, then update npmDepsHash.
{
  lib,
  buildNpmPackage,
  nodejs,
  autoPatchelfHook,
  makeWrapper,
  stdenv,
}:
buildNpmPackage {
  pname = "seo";
  version = "0.2.41";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./package.json
      ./package-lock.json
    ];
  };
  npmDepsHash = "sha256-YpS0JhmWNUln+cHhtrOy7846e3KqC9vTPdRS0Z43GP0=";

  # No dependency ships an install script; nothing to build.
  npmFlags = [ "--ignore-scripts" ];
  dontNpmBuild = true;

  # Prebuilt native modules (libsql, keyring) link against libstdc++.
  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    # npm keeps every platform build matching os/cpu, musl included.
    rm -rf node_modules/@libsql/*-musl* node_modules/@napi-rs/keyring-*-musl*
    mkdir -p $out/lib/seo
    cp -r node_modules $out/lib/seo/
    makeWrapper ${lib.getExe nodejs} $out/bin/seo \
      --add-flags $out/lib/seo/node_modules/seo/dist/cli.js \
      --set-default SEO_TELEMETRY_DISABLED 1 \
      --set-default NO_UPDATE_NOTIFIER 1
    runHook postInstall
  '';

  meta = {
    description = "Local-first SEO and AI-search audit CLI and MCP server";
    homepage = "https://seoskill.dev";
    license = lib.licenses.asl20;
    mainProgram = "seo";
    platforms = lib.platforms.linux;
  };
}
