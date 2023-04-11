{
	description = "A very basic flake";

	inputs = {
		#flake-utils.url = "github:numtide/flake-utils";
		nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
		nixos-generators = {
			url = "github:nix-community/nixos-generators";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};

	outputs = { self, nixpkgs, nixos-generators, ... }:
	let
		system = "x86_64-linux";
		pkgs = nixpkgs.legacyPackages.${system};
	in {

		packages.x86_64-linux = {
			machine = nixos-generators.nixosGenerate {
			  system = "x86_64-linux";
			  modules = [
				./configuration.nix
			  ];
			  format = "iso";
			};
		};

	};
}
