{ stdenv
, fetchFromGitHub
, lib
, libgcc
, glibc
, avahi
, openssl
, curl
, ndi
, tree
, ffmpeg_5-full
}:

stdenv.mkDerivation rec {
  pname = "ndi-monitor";
  version = "f4ae6506d308b1b847e449833aa4cea3555caf15";

  src = fetchFromGitHub {
    owner = "lplassman";
    repo = "NDI-Monitor";
    rev = version;
    sha256 = "sha256-YLNvFdyqKb6DJV/cmdF8O5hmxOOqCCFbwGlFxI6rpW0=";
  };

  configurePhase = ''
    mkdir -p $out/{lib,bin,assets,include,share}

    cp ${ndi}/include/* $out/include/
    cp ${ndi}/lib/* $out/lib/
    cp ${glibc}/lib/libdl.so $out/lib/
    cp ${src}/include/* $out/include/
    cp ${src}/ndi_monitor.cpp ndi_monitor.cpp
    cp ${src}/assets/* $out/assets/

    sed -i 's/0.0.0.0:80/0.0.0.0:8080/g' ndi_monitor.cpp
    sed -i "s#/opt/ndi_monitor#$out#g" ndi_monitor.cpp
    sed -i "s#/usr/local/bin#${ffmpeg_5-full}/bin#g" ndi_monitor.cpp
  '';

  buildInputs = [ libgcc ndi ];

  buildPhase = ''
   g++ -std=c++14 -pthread -Wl,--allow-shlib-undefined -Wl,--as-needed \
       -I${ndi}/include -I$out/include \
       -L$out/lib \
       -o $out/bin/ndi_monitor \
       ndi_monitor.cpp ${src}/mongoose.c ${src}/mjson.c \
       -lndi -ldl
  '';

  installPhase = ''
    chmod +x $out/bin/ndi_monitor
  '';

  meta = with lib; {
    homepage = "https://github.com/lplassman/NDI-Monitor";
    description = "Connects to a Full NDI stream and outputs to a connected display";
    platforms = ["x86_64-linux"];
    license = licenses.mit;
  };
}
