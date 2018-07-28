# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  systemd.generators.systemd-gpt-auto-generator = "/dev/null";

  # networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.wireless.enable = true;

  # Select internationalisation properties.
  # i18n = {
  #   consoleFont = "Lat2-Terminus16";
  #   consoleKeyMap = "us";
  #   defaultLocale = "en_US.UTF-8";
  # };

  # Set your time zone.
  # time.timeZone = "Europe/Amsterdam";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
      vim tmux wpa_supplicant lynx neofetch zsh oh-my-zsh moc wget git hugo go python
  ];

  networking.firewall.enable = false;

  users.users.oem =
    { isNormalUser = true;
      home = "/home/oem";
      extraGroups = [ "wheel" "audio" ];
      shell = pkgs.zsh;
    };

  programs.tmux.enable = true;
  programs.tmux.extraTmuxConf = ''
    bind R source-file /etc/tmux.conf \; display-message "Config reloaded..."
    set -g status-bg black
    set -g status-fg white
    set -g pane-border-style fg=colour239
    set -g pane-active-border-style fg=magenta
    set -g status-left "[#S]"
    set -g status-right '%Y-%m-%d %H:%M'
    set-window-option -g allow-rename off
  '';

  programs.zsh.enable = true;
  programs.zsh.ohMyZsh.enable = true;
  programs.zsh.ohMyZsh.theme = "minimal";
  programs.zsh.ohMyZsh.plugins = [ "git" ];

  programs.zsh.interactiveShellInit = ''
    export TMUX_TMPDIR=~/.tmux/tmp
  '';

  #services.openssh = 
  #{ enable = true;
  #  hostKeys = [ { path = "/etc/ssh/ssh_host_ed25519_key"; type = "ed25519"; } ];
  #  passwordAuthentication = false;
  #  permitRootLogin = "no";
  #};

#  services.openssh.enable = true;
#  services.openssh.hostKeys = [ { path = "/etc/ssh/ssh_host_ed25519_key"; type = "ed25519"; } ];
#  services.openssh.passwordAuthentication = false;
#  services.openssh.permitRootLogin = "no";

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.bash.enableCompletion = true;
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  #networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable the X11 windowing system.
  # services.xserver.enable = true;
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.extraUsers.guest = {
  #   isNormalUser = true;
  #   uid = 1000;
  # };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.03"; # Did you read the comment?

}
