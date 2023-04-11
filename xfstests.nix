{ pkgs, ... }:
{
	fileSystems."/mnt/test" = {
		device = "/dev/disk/by-label/test";
		fsType = "xfs";
	};

	fileSystems."/mnt/scratch" = {
		device = "/dev/disk/by-label/scratch";
		fsType = "xfs";
	};

	# Setup envirionment
	environment.variables.HOST_OPTIONS = "${pkgs.xfstests-env}/xfstests-config";

	# xfstests related
	users.users.fsgqa = {
		isNormalUser  = true;
		description  = "Test user";
	};

	users.users.fsgqa2 = {
		isNormalUser  = true;
		description  = "Test user";
	};

	users.users.fsgqa-123456 = {
		isNormalUser  = true;
		description  = "Test user";
	};

	nixpkgs.overlays = [(final: prev: {
		xfstests-env = final.callPackage ./derivation.nix {};
	})];
	environment.systemPackages = [
		pkgs.xfstests-env
	];

	systemd.services.xfstests = {
		enable = true;
		serviceConfig = {
			Type = "oneshot";
			StandardOutput = "tty";
			StandardError = "tty";
			User = "root";
			Group = "root";
                        WorkingDirectory = "/root";
		};
		after = [ "network.target" "network-online.target" "local-fs.target" ];
		wants = [ "network.target" "network-online.target" "local-fs.target" ];
		wantedBy = [ "multi-user.target" ];
                postStop = ''
			for module in ${pkgs.xfstests-env}/modules/*.ko; do
				${pkgs.kmod}/bin/rmmod $module;
			done;
			# Auto poweroff
			# ${pkgs.systemd}/bin/systemctl poweroff;
		'';
		script = ''
			for module in ${pkgs.xfstests-env}/modules/*.ko; do
				${pkgs.kmod}/bin/insmod $module;
			done;

			${pkgs.bash}/bin/bash -lc \
				"${pkgs.xfstests}/bin/xfstests-check -d $(cat ${pkgs.xfstests-env}/totest)"
			# Beep beep... Human... back to work
			echo -ne '\007'
		'';
	};
}
