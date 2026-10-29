# $NetBSD$

DISTNAME=	codex-0.164.0
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=openai/}
GITHUB_TAG=	rust-v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/openai/codex/
COMMENT=	OpenAI terminal-based coding agent
LICENSE=	apache-2.0

WRKSRC=		${WRKDIR}/codex-rust-v${PKGVERSION_NOREV}/codex-rs
USE_LANGUAGES=	c c++
USE_TOOLS+=	bash git gmake perl pkg-config

# V8, bindgen, and the host's native build dependencies.
TOOL_DEPENDS+=	clang-[0-9]*:../../lang/clang
TOOL_DEPENDS+=	cmake-[0-9]*:../../devel/cmake
TOOL_DEPENDS+=	ninja-build-[0-9]*:../../devel/ninja-build
TOOL_DEPENDS+=	protobuf-[0-9]*:../../devel/protobuf
TOOL_DEPENDS+=	patchelf-[0-9]*:../../devel/patchelf
TOOL_DEPENDS+=	sqlite3-[0-9]*:../../databases/sqlite3
TOOL_DEPENDS+=	python313-[0-9]*:../../lang/python313
BUILD_DEPENDS+=	pkgconf-[0-9]*:../../devel/pkgconf

RUN_DEPENDS+=	git-base-[0-9]*:../../devel/git-base
RUN_DEPENDS+=	python313-[0-9]*:../../lang/python313
RUN_DEPENDS+=	ripgrep-[0-9]*:../../textproc/ripgrep

.include "git-crates.mk"
.include "cargo-depends.mk"
# Use pkgsrc's prebuilt NetBSD/amd64 Rust distribution.
RUST_TYPE=	bin
.include "../../lang/rust/cargo.mk"
CARGO=		${FILESDIR}/cargo-ulimit.sh
.include "../../security/openssl/buildlink3.mk"

GN_COMMIT=	938087829fcbcc8fd87835ee301dd522c7637685
GN_DISTFILE=	gn-${GN_COMMIT}.tar.gz
GN_SRC=		${WRKDIR}/gn-src
DISTFILES+=	${GN_DISTFILE}
SITES.${GN_DISTFILE}+=	https://gn.googlesource.com/gn/+archive/${GN_COMMIT}.tar.gz
EXTRACT_DIR.${GN_DISTFILE}=	${GN_SRC}

.for user name hash in ${CARGO_GITHUB_CRATES}
EXTRACT_DIR.${name}-${hash}.tar.gz=	${WRKDIR}/codex-rust-v${PKGVERSION_NOREV}
.endfor

CARGO_ARGS=	build --release --offline --jobs=4 \
	-p codex-cli --bin codex --bin logs_client \
	-p codex-code-mode-host --bin codex-code-mode-host
MAKE_ENV+=	CARGO_BUILD_JOBS=4 CARGO_NET_OFFLINE=true CARGO_PROFILE_RELEASE_LTO=off V8_FROM_SOURCE=1
MAKE_ENV+=	GN=${GN_SRC}/out/gn NINJA=${PREFIX}/bin/ninja
MAKE_ENV+=	PYTHON=${PREFIX}/bin/python3.13 CLANG_BASE_PATH=${PREFIX}
MAKE_ENV+=	LIBCLANG_PATH=${PREFIX}/lib
MAKE_ENV+=	LD_LIBRARY_PATH=${PREFIX}/lib
MAKE_ENV+=	GN_ARGS=${GN_ARGS:Q}
GN_ARGS=	clang_use_chrome_plugins=false fatal_linker_warnings=false \
		is_clang=true use_lld=false use_custom_libcxx=true \
		use_custom_libunwind=true use_libcxx_modules=false \
		use_sysroot=false use_glib=false \
		rust_sysroot_absolute="${PREFIX}" enable_rust=false \
		enable_rust_cxx=false enable_pkeys=false \
		icu_use_data_file=true v8_enable_temporal_support=false \
		v8_enable_cet_ibt=true \
		extra_cppflags="-D_NETBSD_SOURCE -idirafter ${PREFIX}/include -idirafter /usr/X11R7/include" \
		extra_ldflags="-Wno-error=unused-command-line-argument -L${PREFIX}/lib -L/usr/X11R7/lib"

INSTALLATION_DIRS=	bin \
			share/bash-completion/completions \
			share/fish/vendor_completions.d \
			share/zsh/site-functions \
			share/doc/codex

post-patch:
	${SETENV} WRKSRC=${WRKSRC:Q} CARGO_VENDOR_DIR=${CARGO_VENDOR_DIR:Q} \
		PREFIX=${PREFIX:Q} WRKDIR=${WRKDIR:Q} \
		${SH} ${FILESDIR}/apply-netbsd-patches.sh

pre-build:
	ulimit -d 8388608 && cd ${GN_SRC} && ${SETENV} CC=${PREFIX}/bin/clang \
		CXX=${PREFIX}/bin/clang++ PYTHON=${PREFIX}/bin/python3.13 \
		${PREFIX}/bin/python3.13 build/gen.py \
		--no-last-commit-position --allow-warnings
	ulimit -d 8388608 && ${PREFIX}/bin/ninja -C ${GN_SRC}/out -j4 gn

post-build:
.for binary in codex codex-code-mode-host logs_client
	${PREFIX}/bin/patchelf --force-rpath --set-rpath ${PREFIX}/lib \
		${WRKSRC}/target/release/${binary}
.endfor
	cd ${WRKSRC}/target/release && ./codex completion bash > codex.bash
	cd ${WRKSRC}/target/release && ./codex completion fish > codex.fish
	cd ${WRKSRC}/target/release && ./codex completion zsh > codex.zsh
	/usr/sbin/paxctl +m ${WRKSRC}/target/release/codex-code-mode-host

do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/target/release/codex \
		${DESTDIR}${PREFIX}/bin/codex
	${INSTALL_PROGRAM} ${WRKSRC}/target/release/codex-code-mode-host \
		${DESTDIR}${PREFIX}/bin/codex-code-mode-host
	${INSTALL_PROGRAM} ${WRKSRC}/target/release/logs_client \
		${DESTDIR}${PREFIX}/bin/codex-logs-client
	${INSTALL_DATA} ${WRKSRC}/target/release/codex.bash \
		${DESTDIR}${PREFIX}/share/bash-completion/completions/codex
	${INSTALL_DATA} ${WRKSRC}/target/release/codex.fish \
		${DESTDIR}${PREFIX}/share/fish/vendor_completions.d/codex.fish
	${INSTALL_DATA} ${WRKSRC}/target/release/codex.zsh \
		${DESTDIR}${PREFIX}/share/zsh/site-functions/_codex
.for doc in CLA.md agents_md.md authentication.md config.md contributing.md \
	example-config.md exec.md execpolicy.md getting-started.md install.md \
	license.md open-source-fund.md sandbox.md skills.md slash_commands.md
	${INSTALL_DATA} ${WRKSRC}/../docs/${doc} \
		${DESTDIR}${PREFIX}/share/doc/codex/${doc}
.endfor

.include "../../mk/bsd.pkg.mk"
