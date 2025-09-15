(define-module (libbitcoin)
  #:use-module (guix)
  #:use-module (guix packages)
  #:use-module (guix licenses)
  #:use-module (guix git-download)
  #:use-module (guix build-system gnu)
  #:use-module (guix search-paths)
  #:use-module (guix utils)
  #:use-module (gnu packages)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages boost)
  #:use-module (gnu packages crypto)
  #:use-module (gnu packages networking)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages tls))

(define (version-with-underscores version)
  (string-map (lambda (x) (if (eq? x #\.) #\_ x)) version))

(define-public boost-1.86
  (package
    (inherit boost)
    (version "1.86.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://archives.boost.io/release/" version
                                  "/source/boost_" (version-with-underscores version)
                                  ".tar.bz2"))
              (sha256
               (base32 "0fsisws4vqk4mvdw0caz1i6zllp3k6sbmm3n3xxcpch10kj8iv8v"))))
    (inputs
     (modify-inputs (package-inputs boost)
       (delete "python-minimal-wrapper")))
    (arguments
     (substitute-keyword-arguments
         (package-arguments boost)
       ((#:tests? _) #f)
       ((#:configure-flags _)
        #~(let ((icu (dirname (dirname (search-input-file
                                      %build-inputs "bin/uconv")))))
          (list
           ;; Auto-detection looks for ICU only in traditional
           ;; install locations.
           (string-append "--with-icu=" icu)
           "--with-toolset=gcc")))
       ((#:make-flags _ #~())
        #~(let ((icu (dirname (dirname (search-input-file
                                      %build-inputs "bin/uconv")))))
            (list "--with-iostreams"
                  "--with-locale"
                  "--with-program_options"
                  "--with-thread"
                  "--with-test"
                  "cxxstd=11"
                  "variant=release"
                  "threading=multi"
                  "toolset=gcc"
                  "link=shared"
                  "warnings=off"
                  "boost.locale.iconv=off"
                  "boost.locale.posix=off"
                  "-sNO_BZIP2=1"
                  "-sNO_ZSTD=1"
                  (string-append "-sICU_PATH=" icu)
                  "-d0"
                  "-q"
                  "--reconfigure"
                  (string-append "linkflags=-Wl,-rpath="
                            (assoc-ref %outputs "out") "/lib")
                  "cxxflags=-Wno-enum-constexpr-conversion")))
       ((#:phases phases)
        #~(modify-phases #$phases
            (delete 'provide-libboost_python)))))
    (home-page "https://www.boost.org/")
    (synopsis "Boost C++ Libraries 1.86.0")
    (description "Latest version of Boost 1.86.0 from upstream.")
    (license boost1.0)))

(define-public libsecp256k1-0.7.0
  (package
   (inherit libsecp256k1)
   (name "libsecp256k1")
    (version "0.7.0")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/bitcoin-core/secp256k1")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "1d0cnd2s607j642h64821mpklfvvzy70mkyl2dlsm5s9lgvndn2p"))
              (modules '((guix build utils)))
              (snippet
               ;; These files are pre-generated, the build system is able to
               ;; re-generate those.
               #~(for-each delete-file '("src/precomputed_ecmult.c"
                                         "src/precomputed_ecmult_gen.c")))))
    (arguments
     '(#:configure-flags '("--enable-module-recovery"
                           "--enable-experimental"
                           "--enable-shared"
                           "--disable-static"
                           "--disable-benchmark")))))

(define-public libbitcoin-system
  (package
   (name "libbitcoin-system")
   (version "4.0.0")
   (source (local-file "./libbitcoin-system" #:recursive? #t))
   (build-system gnu-build-system)
   (native-inputs
    (list pkg-config automake autoconf libtool))
   (propagated-inputs (list boost-1.86 zeromq libsecp256k1-0.7.0))
   (arguments
    (list
     #:configure-flags
     #~(list
        (string-append "--with-boost=" (assoc-ref %build-inputs "boost")))))
   (synopsis "Local dev build of libbitcoin-system")
   (description "Dev version of libbitcoin-system built from local source.")
   (home-page "https://github.com/libbitcoin/libbitcoin-system")
   (license agpl3)))

(define-public libbitcoin-protocol
  (package
    (name "libbitcoin-protocol")
    (version "4.0.0")
    (source (local-file "./libbitcoin-protocol" #:recursive? #t))
    (build-system gnu-build-system)
    (native-inputs (list pkg-config automake autoconf libtool))
    (inputs (list boost-1.86 zeromq libbitcoin-system))
    (arguments
     (list
      #:tests? #f
      #:configure-flags
      #~(list
         (string-append "--with-boost=" (assoc-ref %build-inputs "boost")))))
    (synopsis "Local dev build of libbitcoin-protocol")
    (description "Dev version of libbitcoin-protocol built from local source.")
    (home-page "https://github.com/libbitcoin/libbitcoin-protocol")
    (license agpl3)))

(define-public libbitcoin-network
  (package
    (name "libbitcoin-network")
    (version "4.0.0")
    (source (local-file "./libbitcoin-network" #:recursive? #t))
    (build-system gnu-build-system)
    (native-inputs (list pkg-config automake autoconf libtool))
    (inputs (list boost-1.86 libbitcoin-system))
    (arguments
     (list
      #:tests? #f
      #:configure-flags
      #~(list
         (string-append "--with-boost=" (assoc-ref %build-inputs "boost")))))
    (synopsis "Local dev build of libbitcoin-network")
    (description "Dev version of libbitcoin-network built from local source.")
    (home-page "https://github.com/libbitcoin/libbitcoin-network")
    (license agpl3)))

(define-public libbitcoin-database
  (package
    (name "libbitcoin-database")
    (version "4.0.0")
    (source (local-file "./libbitcoin-database" #:recursive? #t))
    (build-system gnu-build-system)
    (native-inputs (list pkg-config automake autoconf libtool))
    (propagated-inputs (list boost-1.86 libbitcoin-system))
    (arguments
     (list
      #:tests? #f
      #:configure-flags
      #~(list
         (string-append "--with-boost=" (assoc-ref %build-inputs "boost")))))
    (synopsis "Local dev build of libbitcoin-database")
    (description "Dev version of libbitcoin-database built from local source.")
    (home-page "https://github.com/libbitcoin/libbitcoin-database")
    (license agpl3)))

(define-public libbitcoin-consensus
  (package
    (name "libbitcoin-consensus")
    (version "4.0.0")
    (source (local-file "./libbitcoin-consensus" #:recursive? #t))
    (build-system gnu-build-system)
    (native-inputs (list pkg-config automake autoconf libtool))
    (inputs (list libsecp256k1-0.7.0 boost-1.86))
    (arguments
     (list
      #:tests? #f
      #:configure-flags
      #~(list
         (string-append "--with-boost=" (assoc-ref %build-inputs "boost")))))
    (synopsis "Local dev build of libbitcoin-consensus")
    (description "Dev version of libbitcoin-consensus built from local source.")
    (home-page "https://github.com/libbitcoin/libbitcoin-consensus")
    (license agpl3)))

(define-public libbitcoin-blockchain
  (package
    (name "libbitcoin-blockchain")
    (version "4.0.0")
    (source (local-file "./libbitcoin-blockchain" #:recursive? #t))
    (build-system gnu-build-system)
    (native-inputs (list pkg-config automake autoconf libtool))
    (inputs (list libbitcoin-consensus boost-1.86))
    (propagated-inputs (list libbitcoin-database))
    (arguments
     (list
      #:tests? #f
      #:configure-flags
      #~(list
         (string-append "--with-boost=" (assoc-ref %build-inputs "boost")))))
    (synopsis "Local dev build of libbitcoin-blockchain")
    (description "Dev version of libbitcoin-blockchain built from local source.")
    (home-page "https://github.com/libbitcoin/libbitcoin-blockchain")
    (license agpl3)))

(define-public libbitcoin-node
  (package
    (name "libbitcoin-node")
    (version "4.0.0")
    (source (local-file "./libbitcoin-node" #:recursive? #t))
    (build-system gnu-build-system)
    (native-inputs (list pkg-config automake autoconf libtool))
    (inputs (list libbitcoin-blockchain libbitcoin-network boost-1.86))
    (propagated-inputs (list libbitcoin-database libbitcoin-network))
    (arguments
     (list
      #:tests? #f
      #:configure-flags
      #~(list
         (string-append "--with-boost=" (assoc-ref %build-inputs "boost")))))
    (synopsis "Local dev build of libbitcoin-node")
    (description "Dev version of libbitcoin-node built from local source.")
    (home-page "https://github.com/libbitcoin/libbitcoin-node")
    (license agpl3)))

(define-public libbitcoin-server
  (package
    (name "libbitcoin-server")
    (version "4.0.0")
    (source (local-file "./libbitcoin-server" #:recursive? #t))
    (build-system gnu-build-system)
    (native-inputs (list pkg-config automake autoconf libtool))
    (inputs (list libbitcoin-node libbitcoin-protocol boost-1.86))
    (arguments
     (list
      #:tests? #f
      #:configure-flags
      #~(list
         (string-append "--with-boost=" (assoc-ref %build-inputs "boost")))))
    (synopsis "Local dev build of libbitcoin-server")
    (description "Dev version of libbitcoin-server built from local source.")
    (home-page "https://github.com/libbitcoin/libbitcoin-server")
    (license agpl3)))
