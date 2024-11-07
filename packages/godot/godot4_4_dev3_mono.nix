{ lib
, stdenv
, fetchurl
, makeWrapper
, unzip
, mono
, dotnet-sdk_8
, dotnet-runtime_8
}:

stdenv.mkDerivation rec {
  pname = "godot4-4-dev3-mono";  # Changed from godot4-mono to be more specific
  version = "4.4-dev3";

  src = fetchurl {
    url = "https://downloads.tuxfamily.org/godotengine/4.4/dev3/mono/Godot_v4.4-dev3_mono_linux_x86_64.zip";
    sha256 = "K9AWkLnWCyIXPkFUkdAJbJuldrrrOX/8Ysun2iIdelI=";
  };

  nativeBuildInputs = [ 
    makeWrapper 
    unzip
  ];

  buildInputs = [ 
    mono 
    dotnet-sdk_8 
    dotnet-runtime_8 
  ];

  unpackPhase = ''
    unzip $src
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mkdir -p "$out/share/applications"
    mkdir -p "$out/share/icons/hicolor/scalable/apps"

    # Install the binary and data directory
    cp -r Godot_v4.4-dev3_mono_linux_x86_64/* $out/bin/
    mv $out/bin/Godot_v4.4-dev3_mono_linux.x86_64 $out/bin/godot4-4-dev3-mono  # Changed binary name

    # Create desktop entry
    cat > "$out/share/applications/godot4-4-dev3-mono.desktop" << EOF  # Changed desktop file name
    [Desktop Entry]
    Name=Godot Engine 4.4-dev3 (Mono)
    Comment=Multi-platform 2D and 3D game engine with a feature-rich editor
    Exec=$out/bin/godot4-4-dev3-mono
    Icon=godot
    Terminal=false
    Type=Application
    Categories=Development;IDE;
    EOF

    # Wrap the binary to set required environment variables
    wrapProgram $out/bin/godot4-4-dev3-mono \
      --prefix PATH : ${lib.makeBinPath [ mono dotnet-sdk_8 dotnet-runtime_8 ]} \
      --set DOTNET_ROOT ${dotnet-sdk_8} \
      --set GODOT_MONO_PREFIX $out/bin

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://godotengine.org";
    description = "Free and Open Source 2D and 3D game engine with Mono/C# support (4.4-dev3)";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "godot4-4-dev3-mono";
  };
}
