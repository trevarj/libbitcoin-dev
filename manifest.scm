(add-to-load-path "./guix")
(use-modules (guix profiles)
             (guix utils)
             (gnu packages gcc)
             (gnu packages llvm)
             (gnu packages autotools)
             (gnu packages pkg-config)
             (libbitcoin))

(packages->manifest
 (list gcc
       clang
       automake
       autoconf
       glibc
       coreutils
       libtool
       pkg-config
       boost-1.86))
