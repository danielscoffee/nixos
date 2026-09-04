{
  lib,
  pkgs,
  ...
}:
let
  grok-bot = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "grok-bot";
    version = "0.30.0";

    src = pkgs.fetchurl {
      url = "https://downloads.cursor.com/aptrepo/pool/grok-bot/g/gr/grok-bot_${finalAttrs.version}_amd64.deb";
      hash = "sha256-+4iLIgTIpRxxqfX5opE6wQVh8+9pOcEkXsrk6DfUraI=";
    };

    nativeBuildInputs = with pkgs; [
      autoPatchelfHook
      dpkg
      makeShellWrapper
      wrapGAppsHook3
    ];

    buildInputs = with pkgs; [
      alsa-lib
      at-spi2-core
      cairo
      cups
      dbus
      expat
      glib
      gtk3
      libGL
      libdrm
      libgbm
      libx11
      libxcb
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxkbcommon
      libxrandr
      nspr
      nss
      pango
      stdenv.cc.cc.lib
      systemd
    ];

    runtimeDependencies = map lib.getLib (
      with pkgs;
      [
        libappindicator-gtk3
        libnotify
        libpulseaudio
        libsecret
        libuuid
        libxscrnsaver
        libxtst
        pipewire
        speechd-minimal
        systemd
      ]
    );

    unpackPhase = ''
      runHook preUnpack
      dpkg-deb -x "$src" .
      runHook postUnpack
    '';

    dontConfigure = true;
    dontBuild = true;
    dontWrapGApps = true;

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/bin" "$out/lib/grok-bot" "$out/share"
      cp -a "opt/Grok Bot/." "$out/lib/grok-bot/"
      cp -a usr/share/applications usr/share/icons "$out/share/"

      substituteInPlace "$out/share/applications/grok-bot.desktop" \
        --replace-fail 'Exec="/opt/Grok Bot/grok-bot"' "Exec=$out/bin/grok-bot"

      makeShellWrapper "$out/lib/grok-bot/grok-bot" "$out/bin/grok-bot" \
        --prefix PATH : "${lib.makeBinPath [ pkgs.xdg-utils ]}" \
        "''${gappsWrapperArgs[@]}"

      runHook postInstall
    '';

    preFixup = ''
      addAutoPatchelfSearchPath "$out/lib/grok-bot"
    '';

    meta = {
      description = "Grok Bot desktop agent";
      homepage = "https://cursor.com";
      license = lib.licenses.unfree;
      mainProgram = "grok-bot";
      platforms = [ "x86_64-linux" ];
      sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    };
  });
in
{
  home.packages = [ grok-bot ];
}
