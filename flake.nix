{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    esp32 = pkgs.dockerTools.pullImage {
      imageName = "espressif/idf-rust";
      imageDigest = "sha256:4d6ca6c1764225eb07374fb3c0584696bf0e9483abf04d075db27b60bc3e3d49";
      sha256 = "Y8l8B73V+4neNaL3tk0cHkDYW4bWOgTjIRO2fD4Kacw=";
      finalImageName = "espressif/idf-rust";
      finalImageTag = "all_latest";
    };
  in {
    packages.x86_64-linux.esp32 = pkgs.stdenv.mkDerivation {
      name = "esp32";
      src = esp32;
      unpackPhase = ''
        mkdir -p source
        tar -C source -xvf $src
      '';
      sourceRoot = "source";
      nativeBuildInputs = [
        pkgs.autoPatchelfHook
        pkgs.jq
      ];
      buildInputs = [
        pkgs.xz
        pkgs.zlib
        pkgs.libxml2
        pkgs.python2
        pkgs.libudev-zero
        pkgs.stdenv.cc.cc
      ];
      buildPhase = ''
        jq -r '.[0].Layers | @tsv' < manifest.json > layers
      '';
      installPhase = ''
        mkdir -p $out
        for i in $(< layers); do
          tar -C $out -xvf "$i" home/esp/{.cargo,.rustup,export-esp.sh} || true
        done
        mv -t $out $out/home/esp/{.cargo,.rustup,export-esp.sh}
        rmdir $out/home/esp
        rmdir $out/home
        rm -rf $out/.rustup/toolchains/nightly-x86_64-unknown-linux-gnu
        rm -rf $out/.rustup/{downloads,tmp,update-hashes}
        cp -t $out/.rustup ${./settings.toml}
        substituteInPlace $out/export-esp.sh --replace /home/esp/ $out/
      '';
    };
  };
}
