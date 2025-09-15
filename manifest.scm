(add-to-load-path "./guix")
(use-modules (guix profiles)
             (guix utils)
             (libbitcoin))

(packages->manifest
 (list
  libbitcoin-system
  libbitcoin-protocol))
