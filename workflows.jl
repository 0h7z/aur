# Copyright (C) 2022-2024 Heptazhou <zhou@0h7z.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

using OrderedCollections: LittleDict as LDict
using OrderedCollections: OrderedDict as ODict
using TOML: TOML
using YAML: YAML, yaml

const COMPRESS = "zstdmt -17 -M1024M --long"
const NAME, MAIL = "Seele", "seele@0h7z.com"
const PACKAGER = "$NAME <$MAIL>"
const PUSH_NOP = "Everything up-to-date"
const StrOrSym = Union{AbstractString, Symbol}
const URL_AUR = "https://aur.archlinux.org"
const URL_DEB = "https://deb.debian.org/debian"
const YAML.yaml(xs...) = join(map(yaml, xs), "\n")
macro S_str(string)
	:(Symbol($string))
end
const cquote(s::StrOrSym) = "\$'$(escape(s, "'"))'"
const escape(s::StrOrSym, xs...; kw...) = escape_string(s, xs...; kw...)
const escape(sym::Symbol, xs...; kw...) = escape(string(sym), xs...; kw...)
const mirror = [
	raw"https://mirrors.dotsrc.org/archlinux/$repo/os/$arch"
	raw"https://mirrors.kernel.org/archlinux/$repo/os/$arch"
]

const ACT_ARTIFACT(pat::StrOrSym) = ODict(
	S"uses" => S"actions/upload-artifact@v4",
	S"with" => ODict(S"compression-level" => 0, S"path" => pat),
)
const ACT_CHECKOUT(ref::StrOrSym) = ACT_CHECKOUT(
	S"path" => Symbol(ref),
	S"ref"  => Symbol(ref),
)
const ACT_CHECKOUT(xs::Pair...) = ODict(
	S"uses" => S"actions/checkout@v4",
	S"with" => ODict(S"persist-credentials" => false, xs...),
)
const ACT_GH(cmd::StrOrSym, envs::Pair...) = ACT_RUN(
	cmd, envs...,
	S"GH_REPO"  => S"${{ github.repository }}",
	S"GH_TOKEN" => S"${{ secrets.PAT }}",
)
const ACT_INIT(cmd::StrOrSym, envs::Pair...) = ACT_RUN("""
	uname -a
	mkdir ~/.ssh -p && cd /etc/pacman.d
	echo -e 'Server = $(mirror[1])' >> mirrorlist
	echo -e 'Server = $(mirror[2])' >> mirrorlist
	tac mirrorlist > mirrorlist~ && mv mirrorlist{~,} && cd /etc
	sed -r 's/^(COMPRESSZST)=.*/\\1=($COMPRESS)/' -i makepkg.conf
	sed -r 's/^#(MAKEFLAGS)=.*/\\1="-j`nproc`"/' -i makepkg.conf
	sed -r 's/^#(PACKAGER)=.*/\\1="$PACKAGER"/' -i makepkg.conf
	pacman-key --init""", """
	pacman -Syu --noconfirm dbus-daemon-units git pacman-contrib
	sed -r 's/\\b(EUID)\\s*==\\s*0\\b/\\1 < -0/' -i /bin/makepkg
	makepkg --version""", cmd, envs...,
)
const ACT_INIT(pkg::Vector{String}) = ACT_INIT(
	Symbol(join(["pacman -S --noconfirm"; pkg], " ")),
)
const ACT_PUSH(msg::StrOrSym; m = cquote(msg)) = ACT_RUN("""
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
const ACT_RUN(cmd::StrOrSym, envs::Pair...) = ODict(
	S"run" => cmd, S"env" => ODict(envs...),
)
const ACT_RUN(cmd::StrOrSym...) = ACT_RUN.([cmd...])
const ACT_RUN(cmd::StrOrSym) = ODict(S"run" => cmd)
const ACT_SYNC(pkgbase::StrOrSym) = ODict(
	# https://github.com/Heptazhou/github-sync
	S"uses" => S"heptazhou/github-sync@v2.3.0",
	S"with" => ODict(
		S"source_repo"        => Symbol("$URL_AUR/$pkgbase.git"),
		S"source_branch"      => S"master",
		S"destination_branch" => Symbol(pkgbase),
		S"github_token"       => S"${{ secrets.PAT }}",
	),
)
const ACT_UPDT(dict::AbstractDict, rel::StrOrSym) = ACT_RUN.("""
	mkdir .github/packages/$pkg -p
	cd -- .github/packages/$pkg
	apt list -a $(join(src, " ")) 2> /dev/null || true
	apt-cache show $(join(src .* "/$rel", " ")) | tee package.txt
	deb=\$(cat package.txt | grep -Pom1 '^Version: \\K\\S+')
	cd - && cd $pkg
	ver=\$(cat PKGBUILD | grep -Po '^pkgver=\\K\\S+')
	rel=\$(cat PKGBUILD | grep -Po '^pkgrel=\\K\\S+')
	[[ \${ver} != \${deb/[+-]*/} ]] && \
	rel=1 && ver="\${deb/[+-]*/}" || \\
	[[ \${deb} == \$(cat PKGBUILD | grep \
	-Po '^debver=\\K\\S+') ]] || ((rel++))
	sed -re "s/^(debver)=.+/\\1=\$deb/" -i PKGBUILD
	sed -re "s/^(pkgver)=.+/\\1=\$ver/" -i PKGBUILD
	sed -re "s/^(pkgrel)=.+/\\1=\$rel/" -i PKGBUILD
	updpkgsums && makepkg --printsrcinfo > .SRCINFO\
	""" for (pkg, src) ∈ dict
)

const JOB_MAKE(pkgbases::Vector{String}, tag::StrOrSym) = ODict(
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
const JOB_SYNC(pkgbase::String) = ODict(
	S"runs-on" => S"ubuntu-latest",
	S"steps"   => [ACT_CHECKOUT(), ACT_SYNC(pkgbase)],
)
const JOB_UPDT(dict::AbstractDict, rel::StrOrSym) = ODict(
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
			echo 'deb $URL_DEB unstable main' >> /etc/apt/sources.list
			echo 'deb $URL_DEB testing  main' >> /etc/apt/sources.list
			echo 'deb $URL_DEB stable   main' >> /etc/apt/sources.list
			echo '\${{ secrets.SSH_PUB }}'    > ~/.ssh/id_ecdsa.pub
			echo '\${{ secrets.SSH_KEY }}'    > ~/.ssh/id_ecdsa
			chmod 600 ~/.ssh/* && apt update  2> /dev/null"""
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
			S"on" => ODict(
				S"workflow_dispatch" => nothing,
				S"push" => ODict(
					S"branches" => ["master"],
					S"paths"    => [q],
				),
			),
			S"jobs" => ODict(
				S"makepkg" => JOB_MAKE(pkgbases, readchomp(q)),
			),
		),
	)
end
function syncpkg(pkgbases::Vector{String})
	p = s -> isdigit(s[begin]) ? Symbol(:_, s) : Symbol(s)
	f = ".github/workflows/repo-sync.yml"
	mkpath(dirname(f))
	write(f,
		yaml(
			S"on" => ODict(
				S"workflow_dispatch" => nothing,
				S"push" => ODict(
					S"branches" => ["master"],
					S"paths"    => [f],
				),
				S"schedule" => [ODict(S"cron" => "0 */4 * * *")],
			),
			S"jobs" => ODict(
				@. p(pkgbases) => JOB_SYNC(pkgbases)
			),
		),
	)
end
function updtpkg(dict::AbstractDict, rel::StrOrSym)
	f = ".github/workflows/repo-updt.yml"
	mkpath(dirname(f))
	write(f,
		yaml(
			S"on" => ODict(
				S"workflow_dispatch" => nothing,
				S"push" => ODict(
					S"branches" => ["master"],
					S"paths"    => [f],
				),
				S"schedule" => [ODict(S"cron" => "0 */8 * * *")],
			),
			S"jobs" => ODict(
				S"updtpkg" => JOB_UPDT(dict, rel),
			),
		),
	)
end

# https://aur.archlinux.org/packages
const pkg = ODict(
	# [depends..., pkgbase]    => (sync, make, pkgver_pkgrel),
	["7-zip-full"]             => (1, 1, "23.01-4"),
	["apt-zsh-completion"]     => (1, 0, "5.9-1"),
	["conda-zsh-completion"]   => (1, 0, "0.11-1"),
	["glibc-linux4"]           => (1, 0, "2.38-1"),
	["iraf-bin"]               => (1, 1, "2.18-1"),
	["libcurl-julia-bin"]      => (1, 1, "1.10-1"),
	["locale-mul_zz"]          => (1, 0, "2.0-3"),
	["mingw-w64-zlib", "nsis"] => (1, 1, "3.09-1"),
	["wine-wow64"]             => (1, 0, "9.6-1"),
	["wine64"]                 => (0, 1, "9.6-1"),
	["xgterm-bin"]             => (1, 0, "2.1-2"),
	["yay"]                    => (1, 1, "12.3.5-1"),
)
for (k, v) ∈ filter((k, v)::Pair -> Bool(v[2]), pkg)
	makepkg(k, v[3])
end
syncpkg(sort!(reduce(∪, findall(Bool ∘ first, pkg))))

# https://tracker.debian.org/
const deb = ODict(
	# (pkgbase)    => [provides...],
	("iraf-bin")   => ["iraf", "iraf-noao"],
	("xgterm-bin") => ["xgterm"],
)
updtpkg(deb, "sid")

