self: super: rec {
  # https://github.com/NixOS/nixpkgs/blob/c339c066b893e5683830ba870b1ccd3bbea88ece/nixos/modules/programs/nix-ld.nix#L44
  # > We currently take all libraries from systemd and nix as the default.
  pythonldlibpath = super.lib.makeLibraryPath (with super; [
    zlib zstd stdenv.cc.cc curl openssl attr libssh bzip2 libxml2 acl libsodium util-linux xz systemd
  ]);
  # here we are overriding python program to add LD_LIBRARY_PATH to it's env
  python = super.stdenv.mkDerivation {
    name = "python";
    buildInputs = [ super.makeWrapper ];
    src = super.python313;
    installPhase = ''
      mkdir -p $out/bin
      cp -r $src/* $out/
      wrapProgram $out/bin/python3 --set LD_LIBRARY_PATH ${pythonldlibpath}
      wrapProgram $out/bin/python3.13 --set LD_LIBRARY_PATH ${pythonldlibpath}
    '';
  };
  poetry = super.stdenv.mkDerivation {
    name = "poetry";
    buildInputs = [ super.makeWrapper ];
    src = super.poetry;
    installPhase = ''
      mkdir -p $out/bin
      cp -r $src/* $out/
      wrapProgram $out/bin/poetry --set LD_LIBRARY_PATH ${pythonldlibpath}
    '';
  };
}