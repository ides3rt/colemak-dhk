#!/usr/bin/env bash

Program="${0##*/}"

Err() {
	printf '%s\n' "$Program: $2" 1>&2
	(( $1 > 0 )) && exit $1
}

(( $# > 0 )) && Err 2 "needn't argument..."

((UID)) && Err 2 'required root privileges...'

if ! type -P gzip &>/dev/null; then
	Err 1 'denpendency, `gzip`, not found...'
fi

Basedir="${0%/*}"/src

if [[ ! -d $Basedir ]]; then
	Err 0 "$Basedir: not found, use \`git clone\` instead..."

	if ! type -P git &>/dev/null; then
		Err 0 'optional dependency, `git`, not found...'
		read -p 'Do you want to install it? [Y/n]: '

		case ${REPLY,,} in
			yes|y|'')

				if type -P pacman &>/dev/null; then
					pacman -Sy --noconfirm git || Err 1 'failed to install git(1)...'

				elif type -P apt-get &>/dev/null; then
					apt-get update -y
					apt-get install -y git || Err 1 'failed to install git(1)...'

				else
					Err 1 "package manager not supported, yet..."

				fi ;;

			no|n)
				exit 1 ;;

			*)
				Err 1 'invaild reply...' ;;
		esac
	fi

	URL=https://github.com/ides3rt/grammak
	git clone -q "$URL" || Err 1 'failed to use `git clone`...'

	Basedir="${URL##*/}"/src
fi

Xkbdir="$Basedir"/xkb
Xkbdest=/usr/share/X11/xkb

Console="$Basedir"/console
Consdest=/usr/share/kbd/keymaps/i386/grammak

for File in "$Xkbdir"/{us,evdev.xml} "$Console"/grammak{,-iso}.map; {
	[[ -f $File ]] || Err 0 "$File: not found..."
	(( ErrCount++ ))
}

(( ErrCount > 0 )) && Err 1 "$ErrCount file(s) not found, aborted..."

if ! cp "$Xkbdir"/us "$Xkbdest"/symbols/us; then
	Err 0 'xkb/us: installation failed...'
	(( ErrCount++ ))
fi

if ! cp "$Xkbdir"/evdev.xml "$Xkbdest"/rules/evdev.xml; then
	Err 0 'xkb/evdev.xml: installation failed...'
	(( ErrCount++ ))
fi

if ! { mkdir -p "$Consdest" && \
	gzip -k "$Console"/* && \
	mv "$Console"/*.gz "$Consdest"; }
then
	Err 0 "${Console##*/}: installation failed..."
	(( ErrCount++ ))
fi

Err 0 "installation was finished with ${ErrCount:-0} error(s)..."
