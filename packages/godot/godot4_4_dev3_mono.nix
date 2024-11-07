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

    preConfigure = ''
    export HOME=$PWD
    export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
    export DOTNET_CLI_TELEMETRY_OPTOUT=1
    export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
    export DOTNET_ROOT=${dotnet-sdk_8}
    
    # Set .NET versions
    export FrameworkVersion="6.0.33"
    export RuntimeVersion="6.0.33"

    # Set up NuGet configuration
    mkdir -p $HOME/.nuget/NuGet
    cat > $HOME/.nuget/NuGet/NuGet.Config << EOF
    <?xml version="1.0" encoding="utf-8"?>
    <configuration>
      <packageSources>
        <add key="nuget.org" value="https://api.nuget.org/v3/index.json" protocolVersion="3" />
      </packageSources>
    </configuration>
    EOF

    # Set up NuGet packages directory
    mkdir -p $HOME/.nuget/packages

    # Patch project files
    find . -name "*.csproj" -type f -exec sed -i \
      -e 's/6.0.35/6.0.33/g' \
      -e 's/<TargetFramework>net6.0/<TargetFramework>net6.0-windows/g' \
      {} +
    
    # Link the NuGet packages
    ln -s ${nugetDeps}/lib/dotnet/store/* $HOME/.nuget/packages/
  '';

  buildPhase = ''
    runHook preBuild

    # First build to get the editor binary with Mono enabled
    scons platform=linuxbsd \
      target=editor \
      module_mono_enabled=yes \
      mono_glue=no \
      use_pulseaudio=${if withPulseaudio then "yes" else "no"} \
      use_fontconfig=${if withFontconfig then "yes" else "no"} \
      use_udev=${if withUdev then "yes" else "no"} \
      speech_enabled=${if withSpeechd then "yes" else "no"}

    # Generate glue sources
    ./bin/godot.linuxbsd.editor.x86_64.mono --headless --generate-mono-glue modules/mono/glue

    # Rebuild with glue
    scons platform=linuxbsd \
      target=editor \
      module_mono_enabled=yes \
      mono_glue=yes \
      use_pulseaudio=${if withPulseaudio then "yes" else "no"} \
      use_fontconfig=${if withFontconfig then "yes" else "no"} \
      use_udev=${if withUdev then "yes" else "no"} \
      speech_enabled=${if withSpeechd then "yes" else "no"}

    # Make the build script executable and run it with Python
    chmod +x modules/mono/build_scripts/build_assemblies.py
    python3 modules/mono/build_scripts/build_assemblies.py \
      --godot-output-dir ./bin \
      --godot-platform linuxbsd

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # Create necessary directories
    mkdir -p $out/bin
    mkdir -p "$out/share/applications"
    mkdir -p "$out/share/icons/hicolor/scalable/apps"

    # Install the binary and data directory
    cp -r bin/* $out/bin/
    mv $out/bin/godot.* $out/bin/godot4-mono

    # Create desktop entry
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

    # Install icons
    cp icon.svg "$out/share/icons/hicolor/scalable/apps/godot.svg"
    cp icon.png "$out/share/icons/godot.png"

    # Wrap the binary to set required environment variables
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
