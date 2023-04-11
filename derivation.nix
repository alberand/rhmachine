{ pkgs, ... }:
pkgs.stdenv.mkDerivation {
	name = "xfstests-env";
	src = ./.;

	LC_ALL = "en_US.UTF-8";

	installPhase = ''
		# Copy the generated result
		mkdir -p $out
		mkdir -p $out/modules
		cp ./xfstests-config $out/
		cp ./totest $out/
		#cp xfs.ko $out
	'';
}
