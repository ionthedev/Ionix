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
, speech-dispatcher ? null
, fontconfig
, udev
, mono
, dotnet-sdk_8
, dotnet-runtime_8
, mkNugetDeps
, callPackage
}:

let
  nugetDeps = mkNugetDeps {
    name = "godot-mono-deps";
    nugetDeps = import ./deps.nix;
  };

  withPulseaudio = true;
  withDbus = true;
  withSpeechd = speech-dispatcher != null;
  withFontconfig = true;
  withUdev = true;
in
stdenv.mkDerivation rec {
  pname = "godot4-mono";
  version = "4.4-dev3";

  src = fetchFromGitHub {
    owner = "godotengine";
    repo = "godot";
    rev = "f4af8201bac157b9d47e336203d3e8a8ef729de2";
    hash = "sha256-ELOdePMqqrkejdkld8/7bxMFqBQ+PIZhAF4aGQPjO90=";
  };

  nativeBuildInputs = [
    scons
    pkg-config
    python3
    makeWrapper
    mono
    dotnet-sdk_8
    dotnet-runtime_8
    nugetDeps
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
    pulseaudio
    dbus
    fontconfig
    udev
  ] ++ lib.optional withSpeechd speech-dispatcher;

  enableParallelBuilding = true;

  configurePhase = ''
    runHook preConfigure
    export HOME="$NIX_BUILD_ROOT"
    export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
    export DOTNET_CLI_TELEMETRY_OPTOUT=1
    # Link the NuGet packages
    mkdir -p $HOME/.nuget/packages
    ln -s ${nugetDeps}/lib/dotnet/store $HOME/.nuget/packages
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    scons platform=linuxbsd \
      target=editor \
      module_mono_enabled=yes \
      mono_glue=no \
      use_pulseaudio=${if withPulseaudio then "yes" else "no"} \
      use_fontconfig=${if withFontconfig then "yes" else "no"} \
      use_udev=${if withUdev then "yes" else "no"} \
      speech_enabled=${if withSpeechd then "yes" else "no"}

    ./bin/godot.linuxbsd.editor.x86_64.mono --headless --generate-mono-glue modules/mono/glue

    scons platform=linuxbsd \
      target=editor \
      module_mono_enabled=yes \
      mono_glue=yes \
      use_pulseaudio=${if withPulseaudio then "yes" else "no"} \
      use_fontconfig=${if withFontconfig then "yes" else "no"} \
      use_udev=${if withUdev then "yes" else "no"} \
      speech_enabled=${if withSpeechd then "yes" else "no"}

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
