{
  description = "Mimsa";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        oldCompilerVersion = "ghc945";

        # we are going to build ormolu and hlint with an old ghc that isn't
        # broken
        oldHaskell = pkgs.haskell // {
          packages = pkgs.haskell.packages // {
            "${oldCompilerVersion}" =
              pkgs.haskell.packages."${oldCompilerVersion}".override {
                overrides = self: super: {
                  # On aarch64-darwin, this creates a cycle for some reason; didn't look too much into it.
                  ghcid = pkgs.haskell.lib.dontCheck (pkgs.haskell.lib.overrideCabal super.ghcid (drv: { enableSeparateBinOutput = false; }));
                  # has wrong version of unix-compat, so we ignore it
                  shelly = pkgs.haskell.lib.doJailbreak super.shelly;
                };

              };
          };
        };

        oldHaskellPackages = haskell.packages.${oldCompilerVersion};

        # current compiler version, ideally, we'll put everything here
        # eventually

        compilerVersion = "ghc962";

        # fix things
        haskell = pkgs.haskell // {
          packages = pkgs.haskell.packages // {
            "${compilerVersion}" =
              pkgs.haskell.packages."${compilerVersion}".override {
                overrides = self: super: {
                  # On aarch64-darwin, this creates a cycle for some reason; didn't look too much into it.
                  ghcid = pkgs.haskell.lib.dontCheck (pkgs.haskell.lib.overrideCabal super.ghcid (drv: { enableSeparateBinOutput = false; }));
                  # has wrong version of unix-compat, so we ignore it
                  shelly = pkgs.haskell.lib.doJailbreak super.shelly;
                  # try and remove cycle
                  cabal-fmt = pkgs.haskell.lib.dontCheck (pkgs.haskell.lib.overrideCabal super.cabal-fmt (drv: {
                    enableSeparateBinOutput = false;
                  }));
                };

              };
          };
        };

        haskellPackages = haskell.packages.${compilerVersion};

        jailbreakUnbreak = pkg:
          pkgs.haskell.lib.doJailbreak (pkg.overrideAttrs (_: { meta = { }; }));

        packageName = "llvm-calc";
      in
      {
        # we're not interested in building with Nix, just using it for deps
        packages.${system}.${packageName} = { };

        defaultPackage = self.packages.${system}.${packageName};

        devShell = pkgs.mkShell {
          buildInputs = with haskellPackages; [
            oldHaskellPackages.hlint
            oldHaskellPackages.ormolu
            ghcid
            cabal-fmt
            cabal-install
            ghc
            pkgs.llvmPackages_15.bintools-unwrapped
            pkgs.llvmPackages_15.clang
            pkgs.llvmPackages_15.libllvm
            pkgs.llvmPackages_15.llvm.dev
            pkgs.llvmPackages_15.libcxxClang
          ];

          # put clang_15 on the path
          shellHook = with pkgs; ''
            # export DYLD_LIBRARY_PATH=${pkgs.llvmPackages_15.libllvm.lib}/lib/
            export LIBCLANG_PATH="${pkgs.llvmPackages_15.libclang}/lib";
          '';

          inputsFrom = builtins.attrValues self.packages.${system};
        };
      });
}
