{ stdenv, lib, cacert, curl, pcre, fuse, glib, glibc, gnused, runCommandLocal, targetPlatform, unzip, zlib, }:


stdenv.mkDerivation rec {
  pname = "davinci-resolve";
  version = "16.2.7-1";

  src = runCommandLocal "${pname}-src"
    rec {
      outputHashMode = "recursive";
      outputHashAlgo = "sha256";
      outputHash = "1bbj7ahz5gzcj5sh1a57a5xajbzyq6q71rahi49w3vwpk46bq3sw";

      impureEnvVars = lib.fetchers.proxyImpureEnvVars;

      nativeBuildInputs = [ curl gnused unzip ];

      # ENV VARS
      SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";

      DOWNLOADID = "9b15a70f5ce1418686be3479612f1134";
      REFERID = "b86a2a4c7a3b4ebfafcc6765f7e3d3a5";
      SITEURL = "https://www.blackmagicdesign.com/api/register/us/download/${DOWNLOADID}";

      USERAGENT = builtins.concatStringsSep " " [
        "User-Agent: Mozilla/5.0 (X11; Linux ${targetPlatform.system})"
        "AppleWebKit/537.36 (KHTML, like Gecko)"
        "Chrome/77.0.3865.75"
        "Safari/537.36"
      ];

      REQJSON = builtins.concatStringsSep "" [
        ''{''
        ''   "firstname": "Jsh", ''
        ''   "lastname": "Cam", ''
        ''   "email": "jdcampbell+spam@me.com", ''
        ''   "phone": "9493916532", ''
        ''   "country": "us", ''
        ''   "state": "California", ''
        ''   "city": "Mission Viejo", ''
        ''   "product": "DaVinci Resolve" ''
        ''}''
      ];

    } ''
    REQJSON="$(  printf '%s' "$REQJSON"   | sed 's/[[:space:]]\+/ /g')"
    USERAGENT="$(printf '%s' "$USERAGENT" | sed 's/[[:space:]]\+/ /g')"

    RESOLVEURL=$(curl \
         -s \
         -H 'Host: www.blackmagicdesign.com' \
         -H 'Accept: application/json, text/plain, */*' \
         -H 'Origin: https://www.blackmagicdesign.com' \
         -H "$USERAGENT" \
         -H 'Content-Type: application/json;charset=UTF-8' \
         -H "Referer: https://www.blackmagicdesign.com/support/download/$REFERID/Linux" \
         -H 'Accept-Encoding: gzip, deflate, br' \
         -H 'Accept-Language: en-US,en;q=0.9' \
         -H 'Authority: www.blackmagicdesign.com' \
         -H 'Cookie: _ga=GA1.2.1849503966.1518103294; _gid=GA1.2.953840595.1518103294' \
         --data-ascii "$REQJSON" \
         --compressed \
         "$SITEURL")
    
    curl \
         --retry 3 --retry-delay 3 \
         -H "Host: sw.blackmagicdesign.com" \
         -H "Upgrade-Insecure-Requests: 1" \
         -H "$USERAGENT" \
         -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" \
         -H "Accept-Language: en-US,en;q=0.9" \
         --compressed \
         "$RESOLVEURL" \
         > resolve.zip

    mkdir -p $out
    unzip resolve.zip -d $out
  '';

  dontStrip = true;

  rpath = (lib.makeLibraryPath [ pcre fuse glib glibc zlib ]);

  installPhase = ''
    mkdir -p $out/bin
    cp DaVinci_Resolve_16.2.7_Linux.run $out/bin
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/DaVinci_Resolve_16.2.7_Linux.run
    patchelf --set-rpath ${rpath} $out/bin/DaVinci_Resolve_16.2.7_Linux.run
  '';
}
