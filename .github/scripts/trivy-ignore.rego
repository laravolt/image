# Trivy ignore policy for scan.sh.
#
# linux-libc-dev holds the kernel's userspace headers. PHP extensions are
# compiled against them, so the image keeps them (install-php-extensions needs
# the compiler toolchain on Debian). No kernel code runs from this package:
# a container uses the host's kernel, so kernel CVEs are fixed by patching the
# host, not the image.
package trivy

import rego.v1

default ignore := false

ignore if input.PkgName == "linux-libc-dev"
