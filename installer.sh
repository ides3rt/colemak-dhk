#!/usr/bin/env bash

progrm=${0##*/}

panic() {
	printf '%s\n' "$progrm: $2" 1>&2
	(( $1 > 0 )) && exit $1
}

(( $# > 0 )) && panic 1 "needn't argument..."

((UID)) && panic 1 'required root privileges...'

if ! type -P gzip &>/dev/null; then
	panic 1 'dependency, `gzip`, not found...'
fi

base_dir=${0%/*}/src

if [[ ! -d $base_dir ]]; then
	panic 0 "$base_dir: not found, use \`git clone\` instead..."

	if ! type -P git &>/dev/null; then
		panic 0 'optional dependency, `git`, not found...'
		read -p 'Do you want to install it? [Y/n]: '

		case ${REPLY,,} in
			yes|y|'')

				if type -P pacman &>/dev/null; then
					pacman -Sy --noconfirm git || panic 1 'failed to install git(1)...'

				elif type -P apt-get &>/dev/null; then
					apt-get update -y
					apt-get install -y git || panic 1 'failed to install git(1)...'

				else
					panic 1 "package manager not supported, yet..."

				fi ;;

			no|n)
				exit 1 ;;

			*)
				panic 1 'invaild reply...' ;;
		esac
	fi

	url=https://github.com/ides3rt/grammak
	git clone -q "$url" || panic 1 'failed to use `git clone`...'

	base_dir=${url##*/}/src
fi

xkb_dir=$base_dir/xkb
xkb_dest=/usr/share/X11/xkb

con_dir=$base_dir/console
con_dest=/usr/share/kbd/keymaps/i386/grammak

for file in "$xkb_dir"/{us,evdev.xml} "$con_dir"/grammak{,-iso}.map; {
	if [[ ! -f $file ]]; then
		panic 0 "$file: not found..."
		(( gone_nr++ ))
	fi
}

(( gone_nr > 0 )) && panic 1 "$gone_nr file(s) not found, aborted..."

if ! cp -- "$xkb_dir"/us "$xkb_dest"/symbols/us; then
	panic 0 'xkb/us: installation failed...'
	(( not_instll++ ))
fi

if ! cp -- "$xkb_dir"/evdev.xml "$xkb_dest"/rules/evdev.xml; then
	panic 0 'xkb/evdev.xml: installation failed...'
	(( not_instll++ ))
fi

if ! { mkdir -p -- "$con_dest" && \
	gzip -k -- "$con_dir"/* && \
	mv -- "$con_dir"/*.gz "$con_dest"; }
then
	panic 0 "${con_dir##*/}: installation failed..."
	(( not_instll++ ))
fi

panic 0 "installation was finished with ${not_instll:-0} error(s)..."
