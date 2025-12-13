{
  description = "zig-humanize";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            zig
            zls
          ];

          shellHook = ''
            echo "zig-humanize development environment loaded!"
            echo ""
            echo "  zig version: $(zig version)"
            echo "  zls version: $(zls version)"
            echo ""
          '';
        };
      }
    );
}
