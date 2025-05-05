{
  description = "Internet Computer SDK Dev Environment (dfx + Motoko + Mops + Rust)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;

        # dfx binary (0.26.1) with patching
        dfx = pkgs.stdenv.mkDerivation {
          name = "dfx";
          src = builtins.fetchTarball {
            url = "https://github.com/dfinity/sdk/releases/download/0.26.1/dfx-0.26.1-x86_64-linux.tar.gz";
            sha256 = "149dkzhryfqij002lbd7xlwzhswbmc3449yihy0i7id1fmmax56c";
          };
          nativeBuildInputs = [ pkgs.patchelf ];
          buildInputs = [ pkgs.stdenv.cc.cc.lib pkgs.zlib ];
          installPhase = ''
            mkdir -p $out/bin
            cp -r * $out/bin/
            chmod +x $out/bin/dfx

            echo "Patching dfx binary for NixOS..."
            patchelf --set-interpreter ${pkgs.glibc.out}/lib/ld-linux-x86-64.so.2 \
                     --set-rpath ${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zlib}/lib:${pkgs.glibc.out}/lib \
                     $out/bin/dfx
          '';
        };

        # Motoko compiler (0.14.9)
        motoko = pkgs.stdenv.mkDerivation {
          name = "motoko";
          src = builtins.fetchTarball {
            url = "https://github.com/dfinity/motoko/releases/download/0.14.9/motoko-Linux-x86_64-0.14.9.tar.gz";
            sha256 = "1fl70ldy0g60zz788g5ri3rvmnk82q99js5n4jd1012xhvqgs1qv"; 
          };
          installPhase = ''
            mkdir -p $out/bin
            cp -r * $out/bin/
            chmod +x $out/bin/moc
          '';
        };

      in {
        devShells.default = pkgs.mkShell {
          name = "icp-dev-env";
          buildInputs = [
            dfx
            motoko
            pkgs.rustup
            pkgs.nodejs
            pkgs.wget
            pkgs.stdenv.cc.cc.lib  # libstdc++ runtime
          ];

          shellHook = ''
            echo "🚀 ICP Development Shell"
            echo "- dfx version: $(dfx --version || echo 'dfx not found')"
            echo "- motoko version: $(moc --version || echo 'motoko not found')"

            # instalar mops (npm)
            if ! command -v mops >/dev/null; then
              echo "📦 Installing mops (Motoko Package Manager)..."
              npm install -g ic-mops
            fi
          '';
        };
      });
}

