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

        # current compiler version, ideally, we'll put everything here
        # eventually

        compilerVersion = "ghc963";

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
            hlint
            ormolu
            # haskell-language-server # this simply does nothing atm
            ghcid
            cabal-fmt
            cabal-install
            ghc
            pkgs.clang_14
            pkgs.llvmPackages_14.llvm
          ];

          # put clang_14 on the path
          #shellHook = with pkgs; ''
          # export PATH="${clang_14}/bin:$PATH"
          #'';

          inputsFrom = builtins.attrValues self.packages.${system};
        };
      });
}
