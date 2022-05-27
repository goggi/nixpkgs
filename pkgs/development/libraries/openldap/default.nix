{ lib
, stdenv
, fetchurl

# dependencies
, cyrus_sasl
, db
, groff
, libsodium
, libtool
, openssl
, systemdMinimal
}:

stdenv.mkDerivation rec {
  pname = "openldap";
  version = "2.6.2";

  src = fetchurl {
    url = "https://www.openldap.org/software/download/OpenLDAP/openldap-release/${pname}-${version}.tgz";
    hash = "sha256-gdCTRSMutiSG7PWsrNLFbAxFtKbIwGZhLn9CGiOhz4c";
  };

  # TODO: separate "out" and "bin"
  outputs = [
    "out"
    "dev"
    "man"
    "devdoc"
  ];

  enableParallelBuilding = true;

  nativeBuildInputs = [
    groff
  ];

  buildInputs = [
    cyrus_sasl
    db
    libsodium
    libtool
    openssl
  ] ++ lib.optionals (stdenv.isLinux) [
    systemdMinimal
  ];

  preConfigure = lib.optionalString (lib.versionAtLeast stdenv.hostPlatform.darwinMinVersion "11") ''
    MACOSX_DEPLOYMENT_TARGET=10.16
  '';

  configureFlags = [
    "--enable-argon2"
    "--enable-crypt"
    "--enable-modules"
    "--enable-overlays"
  ] ++ lib.optionals (stdenv.hostPlatform != stdenv.buildPlatform) [
    "--with-yielding_select=yes"
    "ac_cv_func_memcmp_working=yes"
  ] ++ lib.optional stdenv.isFreeBSD "--with-pic";

  makeFlags= [
    "CC=${stdenv.cc.targetPrefix}cc"
    "STRIP="  # Disable install stripping as it breaks cross-compiling. We strip binaries anyway in fixupPhase.
    "prefix=${placeholder "out"}"
    "sysconfdir=${placeholder "out"}/etc"
    "systemdsystemunitdir=${placeholder "out"}/lib/systemd/system"
    # contrib modules require these
    "moduledir=${placeholder "out"}/lib/modules"
    "mandir=${placeholder "out"}/share/man"
  ] ++ lib.optionals (stdenv.buildPlatform != stdenv.hostPlatform) [
    # Can be unconditional, doing it like this to prevent a mass rebuild.
    "STRIP_OPTS="
  ];

  extraContribModules = [
    # https://git.openldap.org/openldap/openldap/-/tree/master/contrib/slapd-modules
    "passwd/sha2"
    "passwd/pbkdf2"
    "passwd/totp"
  ];

  postBuild = ''
    for module in $extraContribModules; do
      make $makeFlags CC=$CC -C contrib/slapd-modules/$module
    done
  '';

  preCheck = ''
    substituteInPlace tests/scripts/all \
      --replace "/bin/rm" "rm"
  '';

  doCheck = true;

  # The directory is empty and serve no purpose.
  preFixup = ''
    rm -r $out/var
  '';

  installFlags = [
    "prefix=${placeholder "out"}"
    "moduledir=${placeholder "out"}/lib/modules"
    "INSTALL=install"
  ];

  postInstall = ''
    for module in $extraContribModules; do
      make $installFlags install -C contrib/slapd-modules/$module
    done
    chmod +x "$out"/lib/*.{so,dylib}
  '';

  meta = with lib; {
    homepage = "https://www.openldap.org/";
    description = "An open source implementation of the Lightweight Directory Access Protocol";
    license = licenses.openldap;
    maintainers = with maintainers; [ ajs124 das_j hexa ];
    platforms   = platforms.unix;
  };
}
