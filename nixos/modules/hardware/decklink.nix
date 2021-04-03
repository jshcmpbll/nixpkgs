{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardware.decklink;
  kernelPackages = config.boot.kernelPackages;
in
{
  options.hardware.decklink.enable = mkEnableOption "Enable hardware support for the Blackmagic Design Decklink audio/video interfaces.";

  config = mkIf cfg.enable {
    boot.kernelModules = [ "blackmagic" "blackmagic-io" "snd_blackmagic-io" ];
    boot.extraModulePackages = [ kernelPackages.decklink ];
  };
}
