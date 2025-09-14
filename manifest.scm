(use-modules (guix)
             (guix packages)
             (guix licenses)
             (guix git-download)
             (guix build-system gnu)
             (guix utils)
             (gnu packages)
             (gnu packages pkg-config)
             (gnu packages boost)
             (gnu packages crypto)
             (gnu packages networking)
             (gnu packages autotools)
             (gnu packages compression)
             (gnu packages tls))

(define (version-with-underscores version)
  (string-map (lambda (x) (if (eq? x #\.) #\_ x)) version))

(define boost-1.86
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
                            (assoc-ref %outputs "out") "/lib"))))
       ((#:phases phases)
        #~(modify-phases #$phases
            (delete 'provide-libboost_python)))))
    (home-page "https://www.boost.org/")
    (synopsis "Boost C++ Libraries 1.86.0")
    (description "Latest version of Boost 1.86.0 from upstream.")
    (license boost1.0)))

(define libsecp256k1-0.7.0
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

(define libbitcoin-system
  (package
   (name "libbitcoin-system")
   (version "dev")
   (source (local-file "./libbitcoin-system" #:recursive? #t))
   (build-system gnu-build-system)
   (native-inputs
    (list pkg-config automake autoconf libtool))
   (inputs
    (list libsecp256k1-0.7.0
          zeromq
          boost-1.86))
   (arguments
    `(#:configure-flags '("--enable-logging")
                        #:test-target "check"))
   (synopsis "Local dev build of libbitcoin-system")
   (description "Dev version of libbitcoin-system built from local source.")
   (home-page "https://github.com/libbitcoin/libbitcoin-system")
   (license agpl3)))

(packages->manifest
 (list libbitcoin-system))
