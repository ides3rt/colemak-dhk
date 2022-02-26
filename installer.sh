#!/usr/bin/env bash

Program="${0##*/}"

Err() {
	printf '%s\n' "$Program: $2" 1>&2
	(( $1 > 0 )) && exit $1
}

(( $# > 0 )) && Err 1 "don't accept argument..."

((UID)) && Err 1 'root access required...'

type -P gzip &>/dev/null || Err 1 'gzip(1) is required for console installation...'

Basedir="${0%/*}"/src

if [[ ! -d $Basedir ]]; then
	Err 0 "Unable to find '$Basedir', use \`git clone\`..."

	if ! type -P git &>/dev/null; then
		read -p 'git(1) not found, do you want to install it? [Y/n]: '

		case "$REPLY" in
			[Yy][Ee][Ss]|[Yy]|'')

				if type -P pacman &>/dev/null; then
					pacman -Sy --noconfirm git || Err 1 'unable to install git(1)...'

				elif type -P apt-get &>/dev/null; then
					apt-get update -y
					apt-get install -y git || Err 1 'unable to install git(1)...'

				else
					Err 1 "your packages manager not supported by '$Program'..."

				fi ;;

			[Nn][Oo]|[Nn])
				exit 1 ;;

			*)
				Err 1 'invaild reply...' ;;
		esac
	fi

	URL='https://github.com/ides3rt/grammak'
	git clone "$URL" || Err 1 'failed to use `git clone`...'

	Basedir="${URL##*/}"/src
fi

Xkbdir="$Basedir"/xkb
Xkbdest=/usr/share/X11/xkb

Console="$Basedir"/console
Consdest=/usr/share/kbd/keymaps/i386/grammak

for File in "$Xkbdir"/{us,evdev.xml} "$Console"/grammak{,-iso}.map; {
	[[ -f $File ]] || Err 1  "'$File' is missing, aborted..."
}

if ! cp "$Xkbdir"/us "$Xkbdest"/symbols/us; then
	Err 0 "installation of 'xkb/us' failed..."
	(( ErrCount++ ))
fi

if ! cp "$Xkbdir"/evdev.xml "$Xkbdest"/rules/evdev.xml; then
	Err 0 "installation of 'xkb/evdev.xml' failed..."
	(( ErrCount++ ))
fi

if ! { mkdir -p "$Consdest" && \
	gzip -k "$Console"/* && \
	mv "$Console"/*.gz "$Consdest" ;}
then
	Err 0 "installation of '${Console##*/}' failed..."
	(( ErrCount++ ))
fi

Err 0 "Installation was finished with ${ErrCount:-0} error(s)..."
