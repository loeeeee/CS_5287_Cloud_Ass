# /etc/nixos/overlays/code-server-override.nix
self: super: {
  code-server = (super.code-server.override {
    nodejs = super.nodejs_20;
  }).overrideAttrs (oldAttrs: rec {
    version = "4.99.4";
    commit = "47d6d3ada5aadef6d221f3d612401eb3dad9299e";
    src = oldAttrs.src.override {
      rev = "v${version}";
      # hash = "sha256-542os7ji/v2+UyPpPp1KJSB50O5+sUDV7GCZTwO85+I=";
    };
    yarnCache = oldAttrs.yarnCache.overrideAttrs (old: {
      outputHash = "sha256-X+DJcTPE/cswoopDp9IbNm7S3DPqVMMlAyvRrwm6/Sw=";
    });
  });
}