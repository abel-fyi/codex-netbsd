# NetBSD host discovery

Run these read-only commands on the NetBSD build host and keep the output
available to the porting session:

```sh
uname -a
sysctl kern.ostype kern.osrelease hw.machine_arch
df -h / /tmp
pkg_info -V
command -v bmake
bmake -V PKGSRCDIR
```

If `bmake` is not installed or `PKGSRCDIR` is empty, record how pkgsrc is
installed and where its tree lives. Also record the relevant package versions
for Rust, Clang/libclang, CMake, OpenSSL, and pkg-config. Do not paste private
SSH keys, API tokens, or account credentials into this repository.

Before a long build, check available memory and disk space for the pkgsrc work
directory, distfiles, and package output. Codex includes V8, so compiler
resource limits and temporary storage need to be understood early.
