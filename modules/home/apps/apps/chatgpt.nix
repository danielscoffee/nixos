{
  lib,
  pkgs,
  ...
}:
let
  chatgpt = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "chatgpt";
    version = "26.818.41509";

    src = pkgs.fetchurl {
      url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/pool/main/c/chatgpt/chatgpt_${finalAttrs.version}_amd64.deb";
      hash = "sha256-QTlA8YEZtdE+gXe5qIL4zdvd2V37Qk1WVG0ZmylloPI=";
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
      gdk-pixbuf
      glib
      gtk3
      libGL
      libdrm
      libgbm
      libnotify
      libusb1
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

    runtimeDependencies = map lib.getLib [
      pkgs.libGL
      pkgs.libnotify
      pkgs.systemd
    ];

    # Alternative Qt shims and musl addons are unused on this GTK/glibc build.
    autoPatchelfIgnoreMissingDeps = [
      "libQt5Core.so.5"
      "libQt5Gui.so.5"
      "libQt5Widgets.so.5"
      "libQt6Core.so.6"
      "libQt6Gui.so.6"
      "libQt6Widgets.so.6"
      "libc.musl-x86_64.so.1"
    ];

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

      mkdir -p "$out/bin" "$out/lib" "$out/share"
      cp -a usr/lib/chatgpt "$out/lib/"
      cp -a usr/share/applications usr/share/pixmaps "$out/share/"

      makeShellWrapper "$out/lib/chatgpt/codex-launcher" "$out/bin/chatgpt" \
        --prefix PATH : "${
          lib.makeBinPath [
            pkgs.git
            pkgs.glib
            pkgs.xdg-utils
            pkgs.xz
          ]
        }" \
        "''${gappsWrapperArgs[@]}"

      runHook postInstall
    '';

    preFixup = ''
      addAutoPatchelfSearchPath "$out/lib/chatgpt"
    '';

    meta = {
      description = "ChatGPT desktop application by OpenAI";
      homepage = "https://chatgpt.com/download/";
      license = lib.licenses.unfree;
      mainProgram = "chatgpt";
      platforms = [ "x86_64-linux" ];
      sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    };
  });
in
{
  home.packages = [ chatgpt ];
}
