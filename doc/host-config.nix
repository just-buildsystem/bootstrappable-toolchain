{ stdenv
, jo
, coreutils
, gnused
, glibc
}:

stdenv.mkDerivation rec  {
  name = "host-config";

  unpackPhase=''true'';

  nativeBuildInputs = [ glibc jo coreutils gnused ];

  buildPhase = ''
   jo OS=linux \
      ARCH=$(uname -m | sed 's/aarch64/arm64/' ) \
      TOOLCHAIN_CONFIG=$(jo \
        HOST_SYSTEM_HDR_DIR=${glibc.dev}/include \
        HOST_SYSTEM_LIB_DIR=${glibc}/lib \
        HOST_DYNAMIC_LINKER=$(ls ${glibc}/lib/ld-linux-*.so*) \
      ) > host-config.json
  '';

  installPhase = ''
    mkdir -p $out/share
    cp host-config.json $out/share
  '';

}
