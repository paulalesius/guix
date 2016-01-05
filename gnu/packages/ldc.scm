;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2015 Roel Janssen <roel@gnu.org>
;;; Copyright © 2015 Pjotr Prins <pjotr.guix@thebird.nl>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (gnu packages ldc)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system cmake)
  #:use-module (gnu packages)
  #:use-module (gnu packages base)
  #:use-module (gnu packages libedit)
  #:use-module (gnu packages llvm)
  #:use-module (gnu packages textutils)
  #:use-module (gnu packages zip))

(define-public ldc
  (package
    (name "ldc")
    (version "0.16.1")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/ldc-developers/ldc/archive/v"
                    version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "1jvilxx0rpqmkbja4m69fhd5g09697xq7vyqp2hz4hvxmmmv4j40"))))
    (build-system cmake-build-system)
    ;; LDC currently only supports the x86_64 and i686 architectures.
    (supported-systems '("x86_64-linux" "i686-linux"))
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'unpack-submodule-sources
           (lambda* (#:key inputs #:allow-other-keys)
             (let ((unpack (lambda (source target)
                             (with-directory-excursion target
                               (zero? (system* "tar" "xvf"
                                               (assoc-ref inputs source)
                                               "--strip-components=1"))))))
               (and (unpack "phobos-src" "runtime/phobos")
                    (unpack "druntime-src" "runtime/druntime")
                    (unpack "dmd-testsuite-src" "tests/d2/dmd-testsuite")))))
         (add-after 'unpack-submodule-sources 'patch-phobos
           (lambda* (#:key inputs #:allow-other-keys)
             (substitute* "runtime/phobos/std/process.d"
               (("/bin/sh") (which "sh"))
               (("echo") (which "echo")))
             (substitute* "runtime/phobos/std/datetime.d"
               (("/usr/share/zoneinfo/")
                (string-append (assoc-ref inputs "tzdata") "/share/zoneinfo")))
             (substitute* "tests/d2/dmd-testsuite/Makefile"
               (("/bin/bash") (which "bash")))
             #t)))))
    (inputs
     `(("libconfig" ,libconfig)
       ("libedit" ,libedit)
       ("tzdata" ,tzdata)))
    (native-inputs
     `(("llvm" ,llvm)
       ("clang" ,clang)
       ("unzip" ,unzip)
       ("phobos-src"
        ,(origin
           (method url-fetch)
           (uri (string-append
                 "https://github.com/ldc-developers/phobos/archive/ldc-v"
                 version ".tar.gz"))
           (sha256
            (base32
             "0sgdj0536c4nb118yiw1f8lqy5d3g3lpg9l99l165lk9xy45l9z4"))
           (patches (list (search-patch "ldc-disable-tests.patch")))))
       ("druntime-src"
        ,(origin
           (method url-fetch)
           (uri (string-append
                 "https://github.com/ldc-developers/druntime/archive/ldc-v"
                 version ".tar.gz"))
           (sha256
            (base32
             "0z4mkyddx6c4sy1vqgqvavz55083dsxws681qkh93jh1rpby9yg6"))))
       ("dmd-testsuite-src"
        ,(origin
           (method url-fetch)
           (uri (string-append
                 "https://github.com/ldc-developers/dmd-testsuite/archive/ldc-v"
                 version ".tar.gz"))
           (sha256
            (base32
             "0yc6miidzgl9k33ygk7xcppmfd6kivqj02cvv4fmkbs3qz4yy3z1"))))))
    (home-page "http://wiki.dlang.org/LDC")
    (synopsis "LLVM compiler for the D programming language")
    (description
     "LDC is a compiler for the D programming language.  It is based on the
latest DMD frontend and uses LLVM as backend.")
    ;; Most of the code is released under BSD-3, except for code originally
    ;; written for GDC, which is released under GPLv2+, and the DMD frontend,
    ;; which is released under the "Boost Software License version 1.0".
    (license (list license:bsd-3
                   license:gpl2+
                   license:x11-style "http://www.boost.org/LICENSE_1_0.txt"))))
