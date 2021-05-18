{
  description = "mcwhirter.io website";

  inputs = {
    haskellNix.url = "github:input-output-hk/haskell.nix";
    nixpkgs.follows = "haskellNix/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, utils, haskellNix }:
    utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        overlays = [ haskellNix.overlay
          (final: prev: {
            # This overlay adds our project to pkgs
            mcwhirterIoProject =
              final.haskell-nix.project' {
                src = ./.;
                compiler-nix-name = "ghc8104";
              };
          })
        ];

        lib = pkgs.lib;

        # Run with `nix run .#repl`
        repl = utils.lib.mkApp {
          drv = pkgs.writeShellScriptBin "repl" ''
            confnix=$(mktemp)
            echo "builtins.getFlake (toString $(git rev-parse --show-toplevel))" >$confnix
            trap "rm $confnix" EXIT
            nix repl $confnix
          '';
        };
        pkgs = import nixpkgs { inherit system overlays; };
        flake = pkgs.mcwhirterIoProject.flake {};
      in flake // {
        # Built by `nix build .`
        defaultPackage = flake.packages."project:exe:site";
        # Executed by `nix run . -- <args?>`
        defaultApp = flake.packages."project:exe:site";

        apps = (pkgs.mcwhirterIoProject) // { inherit repl; };

        # This is used by `nix develop .` to open a shell for use with
        # `cabal`, `hlint` and `haskell-language-server`
        devShell = pkgs.mcwhirterIoProject.shellFor {
          tools = {
            cabal = "latest";
            hakyll = "latest";
            haskell-language-server = "latest";
            hlint = "latest";
          };
        };
      });
}
