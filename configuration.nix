{
	config,
	pkgs ? import <nixpkgs> {},
	modulesPath,
	lib,
	...
}: let
	# fstests confgiuration
	totest = "/root/vmtest/totest";

	xfstests-overlay = (self: super: {
		xfstests = super.xfstests.overrideAttrs (super: {
			version = "git";
			src = /home/alberand/Projects/xfstests-dev;
		});
	});

	# Custom remote xfstests
	xfstests-overlay-remote = (self: super: {
		xfstests = super.xfstests.overrideAttrs (prev: {
			version = "git";
			src = pkgs.fetchFromGitHub {
				owner = "alberand";
				repo = "xfstests";
				rev = "cbb3b25d72361c4c6c141b03312e7ac2f5d1e303";
				sha256 = "sha256-iVuQWaFOHalHfkeUUXtlFkysB5whpeLFNK823wbaPj4=";
			};
		});
	});

	xfsprogs-overlay = (self: super: {
		xfsprogs = super.xfsprogs.overrideAttrs (prev: {
			version = "git";
			src = fetchGit /home/alberand/Projects/xfsprogs-dev;
			buildInputs = with pkgs; [ gnum4 readline icu inih liburcu ];
		});
	});

	xfsprogs-overlay-remote = (self: super: {
		xfsprogs = super.xfsprogs.overrideAttrs (prev: {
			version = "6.6.2";
			src = pkgs.fetchFromGitHub {
				owner = "alberand";
				repo = "xfsprogs";
				rev = "91bf9d98df8b50c56c9c297c0072a43b0ee02841";
				sha256 = "sha256-otEJr4PTXjX0AK3c5T6loLeX3X+BRBvCuDKyYcY9MQ4=";
			};
		});
	});

	kernel-custom = pkgs.linuxKernel.customPackage {
		version = "6.3.0-rc1";
		configfile = ./.config;
		src = pkgs.fetchFromGitHub {
			owner = "alberand";
			repo = "linux";
			rev = "4520bab7903344ea2ec9543ccc88469b72df016f";
			sha256 = "sha256-isnmGFMUguIqkhDmnRe2s7jxxmeD1nd7lELwzS6kRJM=";
		};
	};
in
{
	imports = [
		./xfstests.nix
		(modulesPath + "/profiles/qemu-guest.nix")
	];

	boot = {
		#kernelParams = ["console=ttyS0,115200n8" "console=ttyS0"];
		consoleLogLevel = lib.mkDefault 7;
		# This is happens before systemd
		postBootCommands = "echo 'Not much to do before systemd :)' > /dev/kmsg";
		crashDump.enable = true;

		# Set my custom kernel
		kernelPackages = kernel-custom;
		# kernelPackages = pkgs.linuxPackages_6_1;
	};

	# Auto-login with empty password
	users.extraUsers.root.initialHashedPassword = "";
	services.getty.autologinUser = lib.mkDefault "root";

	networking.firewall.enable = false;
	networking.hostName = "vm";
	networking.useDHCP = false;
	services.getty.helpLine = ''
		Log in as "root" with an empty password.
		If you are connect via serial console:
		Type CTRL-A X to exit QEMU
	'';

	# Not needed in VM
	documentation.doc.enable = false;
	documentation.man.enable = false;
	documentation.nixos.enable = false;
	documentation.info.enable = false;
	programs.bash.enableCompletion = false;
	programs.command-not-found.enable = false;

	# Do something after systemd started
	systemd.services."serial-getty@ttyS0".enable = true;
	# Add packages to VM
	environment.systemPackages = with pkgs; [
		htop
		util-linux
		xfstests
		tmux
		fsverity-utils
		trace-cmd
		perf-tools
		linuxPackages_latest.perf
		openssl
		xfsprogs
		usbutils
		bpftrace
                xxd
                xterm
                zsh
	];

	services.openssh.enable = true;

	# Apply overlay on the package (use different src as we replaced 'src = ')
	nixpkgs.overlays = [
		xfstests-overlay-remote
		xfsprogs-overlay-remote
	];

	# This value determines the NixOS release from which the default
	# settings for stateful data, like file locations and database versions
	# on your system were taken. It‘s perfectly fine and recommended to leave
	# this value at the release version of the first install of this system.
	# Before changing this value read the documentation for this option
	# (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
	system.stateVersion = "22.11"; # Did you read the comment?
}
