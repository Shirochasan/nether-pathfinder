{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # Zigの最新開発版(0.17.0-dev等)を取得するためのオーバーレイ
    zig-overlay.url = "github:mitchellh/zig-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, zig-overlay }:
      flake-utils.lib.eachDefaultSystem(system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ zig-overlay.overlays.default ];
        };
        # 現時点でNixpkgsで利用可能な最新のLLVMパッケージセット(19など)
        llvmPkgs = pkgs.llvmPackages_19;
      in {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            binutils-unwrapped-all-targets
            llvmPkgs.clang
            pkg-config
            cmake
            ninja
            # ツールチェーン
            pkgs.zigpkgs."master"
            pkgs.jdk21
            pkgs.openjdk8 # Gradleが要求しているバージョンを追加
          ];
          buildInputs = with pkgs; [
            gbenchmark
          ];

          shellHook = ''
            export CC="clang"
            export CXX="clang++"
            # デフォルトは21にする
            export JAVA_HOME=${pkgs.jdk21}
            # Gradleが他のJDKを見つけられるようにパスを通す
            export JDK8_HOME=${pkgs.openjdk8}
            export JDK21_HOME=${pkgs.jdk21}
          '';
        };
      });
}
