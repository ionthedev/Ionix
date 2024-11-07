{ lib
, stdenv
, fetchFromGitHub
, scons
, pkg-config
, python3
, makeWrapper
, vulkan-loader
, libGL
, libX11
, libXcursor
, libXinerama
, libXext
, libXrandr
, libXrender
, libXi
, libXxf86vm
, libxkbcommon
, alsa-lib
, pulseaudio
, dbus
, speech-dispatcher
, fontconfig
, udev
, withPulseaudio ? true
, withDbus ? true
, withSpeechd ? true
, withFontconfig ? true
, withUdev ? true
, mono
, dotnet-sdk_8
, dotnet-runtime_8
}:

stdenv.mkDerivation rec {
  pname = "godot4-mono";
  version = "4.4-dev3";

  src = fetchFromGitHub {
    owner = "godotengine";
    repo = "godot";
    rev = "f4af8201bac157b9d47e336203d3e8a8ef729de2";
    hash = "sha256-K9AWkLnWCyIXPkFUkdAJbJuldrrrOX/8Ysun2iIdelI=";
  };

  nativeBuildInputs = [
    scons
    pkg-config
    python3
    makeWrapper
    mono
    dotnet-sdk_8
    dotnet-runtime_8
  ];

  buildInputs = [
    vulkan-loader
    libGL
    libX11
    libXcursor
    libXinerama
    libXext
    libXrandr
    libXrender
    libXi
    libXxf86vm
    libxkbcommon
    alsa-lib
  ] ++ lib.optional withPulseaudio pulseaudio
    ++ lib.optional withDbus dbus
    ++ lib.optional withSpeechd speech-dispatcher
    ++ lib.optional withFontconfig fontconfig
    ++ lib.optional withUdev udev;

  enableParallelBuilding = true;

  buildPhase = ''
    runHook preBuild

    scons platform=linuxbsd target=editor module_mono_enabled=yes mono_glue=no
    ./bin/godot.linuxbsd.editor.x86_64.mono --headless --generate-mono-glue modules/mono/glue
    scons platform=linuxbsd target=editor module_mono_enabled=yes mono_glue=yes
    python3 modules/mono/build_scripts/build_assemblies.py --godot-output-dir bin

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp -r bin/* $out/bin/
    mv $out/bin/godot.* $out/bin/godot4-mono

    mkdir -p "$out/share/applications"
    mkdir -p "$out/share/icons/hicolor/scalable/apps"

    cat > "$out/share/applications/godot4-mono.desktop" << EOF
    [Desktop Entry]
    Name=Godot Engine 4.4 (Mono)
    Comment=Multi-platform 2D and 3D game engine with a feature-rich editor
    Exec=$out/bin/godot4-mono
    Icon=godot
    Terminal=false
    Type=Application
    Categories=Development;IDE;
    EOF

    cp icon.svg "$out/share/icons/hicolor/scalable/apps/godot.svg"
    cp icon.png "$out/share/icons/godot.png"

    wrapProgram $out/bin/godot4-mono \
      --prefix PATH : ${lib.makeBinPath [ mono dotnet-sdk_8 dotnet-runtime_8 ]} \
      --set DOTNET_ROOT ${dotnet-sdk_8} \
      --set GODOT_MONO_PREFIX $out/bin

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://godotengine.org";
    description = "Free and Open Source 2D and 3D game engine with Mono/C# support";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "godot4-mono";
  };
}
