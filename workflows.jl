# Copyright (C) 2022-2025 Heptazhou <zhou@0h7z.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

using Exts
using TOML: TOML
using YAML: yaml

const COMPRESS = "zstdmt -18 -M1024M --long"
const NAME, MAIL = "Seele", "seele@0h7z.com"
const PACKAGER = "$NAME <$MAIL>"
const PUSH_NOP = "Everything up-to-date"
const URL_AUR = "https://aur.archlinux.org"
const URL_DEB = "https://deb.debian.org/debian"

const cquote(s::SymOrStr)::String = "\$'$(escape(s, "'"))'"
const escape(s::SymOrStr, xs...; kw...) = escape_string(s, xs...; kw...)
const escape(sym::Symbol, xs...; kw...) = escape(string(sym), xs...; kw...)
const mirror = String[
	raw"https://mirrors.dotsrc.org/archlinux/$repo/os/$arch"
	raw"https://mirrors.kernel.org/archlinux/$repo/os/$arch"
]

const ACT_ARTIFACT(pat::SymOrStr) = LDict(
	S"uses" => S"actions/upload-artifact@v4",
	S"with" => LDict(S"compression-level" => 0, S"path" => pat),
)
const ACT_CHECKOUT(ref::SymOrStr) = ACT_CHECKOUT(
	S"path" => Symbol(ref),
	S"ref"  => Symbol(ref),
)
const ACT_CHECKOUT(xs::Pair...) = LDict(
	S"uses" => S"actions/checkout@v4",
	S"with" => ODict(S"persist-credentials" => false, xs...),
)
const ACT_GH(cmd::SymOrStr, envs::Pair...) = ACT_RUN(
	cmd, envs...,
	S"GH_REPO"  => S"${{ github.repository }}",
	S"GH_TOKEN" => S"${{ secrets.PAT }}",
)
const ACT_INIT(cmd::SymOrStr, envs::Pair...) = ACT_RUN("""
	uname -a
	mkdir ~/.ssh -p && cd /etc/pacman.d
	echo -e 'Server = $(mirror[1])' >> mirrorlist
	echo -e 'Server = $(mirror[2])' >> mirrorlist
	tac mirrorlist > mirrorlist~ && mv mirrorlist{~,} && cd /etc
	sed -r 's/^(COMPRESSZST)=.*/\\1=($COMPRESS)/' -i makepkg.conf
	sed -r 's/^#(MAKEFLAGS)=.*/\\1="-j`nproc`"/' -i makepkg.conf
	sed -r 's/^#(PACKAGER)=.*/\\1="$PACKAGER"/' -i makepkg.conf
	pacman-key --init""", """
	pacman -Syu --noconfirm git pacman-contrib
	sed -r 's/\\b(EUID)\\s*==\\s*0\\b/\\1 < -0/' -i /bin/makepkg
	makepkg --version""", cmd, envs...,
)
const ACT_INIT(pkg::Vector{String}) = ACT_INIT(
	Symbol(join(["pacman -S --noconfirm"; pkg], " ")),
)
const ACT_PUSH(msg::SymOrStr; m = cquote(msg)) = ACT_RUN("""
	git version
	git config --global commit.gpgsign true
	git config --global gpg.format ssh
	git config --global init.defaultbranch master
	git config --global log.date iso
	git config --global pull.rebase true
	git config --global safe.directory "*"
	git config --global user.email $MAIL
	git config --global user.name  $NAME
	git config --global user.signingkey ~/.ssh/id_ecdsa.pub
	git add --all && git commit --allow-empty-message -m $m || true
	git pull -ftp && git push |& tee /tmp/push
	git rev-parse HEAD | tee /tmp/head
	sha=`cat /tmp/head` u=\${{ github.api_url }}/repos/\
	\${{ github.repository }}/commits/\$sha/comments
	grep $(cquote(PUSH_NOP)) /tmp/push -ax && exit
	echo @Heptazhou > /tmp/md
	echo '```s'    >> /tmp/md && git show --stat -w >> /tmp/md
	echo '```'     >> /tmp/md && cat /tmp/md | jq -Rs \
	\$'{ body: . }' > /tmp/md.json
	echo \$u && curl -LX POST \
	 -H 'Authorization: token \${{ secrets.PAT }}' \
	 -d @/tmp/md.json \
	\$u""" # https://docs.github.com/rest/commits/comments
)
const ACT_RUN(cmd::SymOrStr, envs::Pair...) = LDict(
	S"run" => cmd, S"env" => ODict(envs...),
)
const ACT_RUN(cmd::SymOrStr...) = ACT_RUN.([cmd...])
const ACT_RUN(cmd::SymOrStr) = LDict(S"run" => cmd)
const ACT_SYNC(pkgbase::SymOrStr) = LDict(
	# https://github.com/Heptazhou/github-sync
	S"uses" => S"heptazhou/github-sync@v2.3.0",
	S"with" => LDict(
		:source_repo        => Symbol("$URL_AUR/$pkgbase.git"),
		:source_branch      => S"master",
		:destination_branch => Symbol(pkgbase),
		:github_token       => S"${{ secrets.PAT }}",
	),
)
const ACT_UPDT(dict::AbstractDict, rel::SymOrStr) = ACT_RUN.(strip("""
	mkdir .github/packages/$pkg -p
	cd -- .github/packages/$pkg
	apt list -a $(join(src, " ")) 2> /dev/null || true
	apt-cache show $(join(src .* "/$rel", " ")) | tee package.txt
	deb=\$(cat package.txt | grep -Pom1 '^Version: \\K\\S+')
	pkg=\${deb/~rc/rc} && cd - && cd $pkg
	ver=\$(cat PKGBUILD | grep -Po '^pkgver=\\K\\S+')
	rel=\$(cat PKGBUILD | grep -Po '^pkgrel=\\K\\S+')
	[[ \${ver} != \${pkg/[+-]*/} ]] && \
	rel=1 && ver="\${pkg/[+-]*/}" ||
	[[ \${deb} == \$(cat PKGBUILD | grep \
	-Po '^debver=\\K\\S+') ]] || ((rel++))
	sed -re "s/^(debver)=.+/\\1=\$deb/" -i PKGBUILD
	sed -re "s/^(pkgver)=.+/\\1=\$ver/" -i PKGBUILD
	sed -re "s/^(pkgrel)=.+/\\1=\$rel/" -i PKGBUILD
	updpkgsums && makepkg --printsrcinfo > .SRCINFO
	""") for (pkg::String, src::Vector{String}) ∈ dict
)

const JOB_MAKE(pkgbases::Vector{String}, tag::SymOrStr) = LDict(
	S"container" => S"archlinux:base-devel",
	S"runs-on" => S"ubuntu-latest",
	S"steps" => [
		ACT_INIT(["github-cli"])
		ACT_CHECKOUT.(sort(pkgbases))
		ACT_RUN.([
			map(pkgbase -> strip("""
			cd $pkgbase
			git rev-parse HEAD | tee ../head
			makepkg -si --noconfirm
			mv -vt .. *.pkg.tar.zst
			"""), pkgbases)
			S"ls -lav *.pkg.tar.zst"
		])
		ACT_ARTIFACT("*.pkg.tar.zst")
		ACT_GH("""
			gh version
			gh release delete \$GH_TAG --cleanup-tag -y || true
			gh release create \$GH_TAG *.pkg.tar.zst --target `cat head` \
			&& cat head""",
			S"GH_TAG" => Symbol(tag),
		)
	],
)
const JOB_SYNC(pkgbase::String) = LDict(
	S"runs-on" => S"ubuntu-latest",
	S"steps"   => [ACT_CHECKOUT(), ACT_SYNC(pkgbase)],
)
const JOB_UPDT(dict::AbstractDict, rel::SymOrStr) = LDict(
	S"container" => S"archlinux:base-devel",
	S"runs-on" => S"ubuntu-latest",
	S"steps" => [
		ACT_INIT(["apt", "debian-archive-keyring", "jq", "openssh"])
		ACT_CHECKOUT(
			S"persist-credentials" => true,
			S"token" => S"${{ secrets.PAT }}",
		)
		ACT_RUN("""
			patch -d / -lp1  < makepkg.patch
			#* https://gitlab.archlinux.org/archlinux/packaging/packages/apt/-/issues/17
			sqv -V && for f in /usr/share/apt/*; do pacman -Qo \$f; cat -n \$f; done
			sed  's/^(brainpoolp384)/# \\1/' -ri /usr/share/apt/default-sequoia.config
			sed  's/Retries "0"/Retries "3"/' -i /etc/apt/apt.conf
			echo 'deb $URL_DEB unstable main' >> /etc/apt/sources.list
			echo 'deb $URL_DEB testing  main' >> /etc/apt/sources.list
			echo 'deb $URL_DEB stable   main' >> /etc/apt/sources.list
			echo '\${{ secrets.SSH_PUB }}'    > ~/.ssh/id_ecdsa.pub
			echo '\${{ secrets.SSH_KEY }}'    > ~/.ssh/id_ecdsa
			chmod 400 ~/.ssh/** && apt update 2> /dev/null"""
		)
		ACT_UPDT(dict, rel)
		ACT_PUSH("Update")
	],
)

function makepkg(pkgbases::Vector{String}, v::String)
	p = pkgbases[end]
	q = ".github/packages/$p/version.txt"
	mkpath(dirname(q))
	write(q, "$p-v$v", "\n")
	f = ".github/workflows/make-$p.yml"
	mkpath(dirname(f))
	write(f,
		yaml(
			:on => LDict(
				:workflow_dispatch => nothing,
				:push => LDict(
					:branches => ["master"],
					:paths    => [q],
				),
			),
			:jobs => LDict(
				:makepkg => JOB_MAKE(pkgbases, readchomp(q)),
			),
			delim = "\n",
		),
	)
end
function syncpkg(pkgbases::Vector{String})
	p = s::String -> isdigit(first(s)) ? Symbol(:_, s) : Symbol(s)
	f = ".github/workflows/repo-sync.yml"
	mkpath(dirname(f))
	write(f,
		yaml(
			:on => LDict(
				:workflow_dispatch => nothing,
				:push => LDict(
					:branches => ["master"],
					:paths    => [f],
				),
				:schedule => [LDict(:cron => "0 */4 * * *")],
			),
			:jobs => LDict(
				@. p(pkgbases) => JOB_SYNC(pkgbases)
			),
			delim = "\n",
		),
	)
end
function updtpkg(dict::AbstractDict, rel::SymOrStr)
	f = ".github/workflows/repo-updt.yml"
	mkpath(dirname(f))
	write(f,
		yaml(
			:on => LDict(
				:workflow_dispatch => nothing,
				:push => LDict(
					:branches => ["master"],
					:paths    => [f],
				),
				:schedule => [LDict(:cron => "0 */8 * * *")],
			),
			:jobs => LDict(
				:updtpkg => JOB_UPDT(dict, rel),
			),
			delim = "\n",
		),
	)
end

# https://aur.archlinux.org/packages
const pkg = LDict(
	# [depends..., pkgbase]    => (sync, make, pkgver_pkgrel),
	["7-zip-full"]             => (1, 1, "24.09-1"),
	["apt-zsh-completion"]     => (1, 0, "5.9-1"),
	["conda-zsh-completion"]   => (1, 0, "0.11-1"),
	["glibc-linux4"]           => (1, 0, "2.38-1"),
	["iraf-bin"]               => (1, 1, "2.18.1-1"),
	["libcurl-julia-bin"]      => (1, 1, "1.11-1"),
	["locale-mul_zz"]          => (1, 0, "2.0-3"),
	["mingw-w64-zlib", "nsis"] => (1, 1, "3.11-1"),
	["python311"]              => (1, 1, "3.11.11-1"),
	["python312"]              => (1, 1, "3.12.10-1"),
	["wine-wow64"]             => (1, 0, "10.6-1"),
	["wine64"]                 => (0, 1, "10.6-1"),
	["xgterm-bin"]             => (1, 0, "2.2-1"),
	["yay"]                    => (1, 1, "12.5.0-1"),
)
for (k, v) ∈ filter((k, v)::Pair -> Bool(v[2]), pkg)
	makepkg(k, v[3])
end
syncpkg(sort!(reduce(∪, findall(Bool ∘ first, pkg))))

# https://tracker.debian.org/
const deb = LDict(
	# (pkgbase)    => [provides...],
	("iraf-bin")   => ["iraf", "iraf-noao"],
	("xgterm-bin") => ["xgterm"],
)
updtpkg(deb, "sid")

