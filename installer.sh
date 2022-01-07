#!/usr/bin/env bash

# It's a mess lol.

Program="${0##*/}"

Err() {
	printf '%s\n' "$Program: $2" 1>&2
	(( $1 > 0 )) && exit $1
}

(( $# > 0 )) && Err 1 "don't accept argument..."

Basedir="${0%/*}"/src

if [[ ! -d "$Basedir/src" ]]; then
	Err 0 "Unable to find '$Basedir/src', use \`git clone\`..."
	if ! type -P git &>/dev/null; then
		read -p 'git(1) not found, do you want to install it? [Y/n]: '
		case "$REPLY" in

			[Yy][Ee][Ss]|[Yy]|'')
				if type -P pacman &>/dev/null; then
					pacman -Syy git || Err 1 'Unable to install git(1)...'
				elif type -P apt-get &>/dev/null; then
					apt-get update
					apt-get install git || Err 1 'Unable to install git(1)...'
				else
					Err 1 "Your packages manager not supported by '$Program'..."
				fi ;;

			[Nn][Oo]|[Nn])
				exit 1 ;;

			*)
				Err 1 'Invaild reply...'
		esac
	fi

	URL='https://github.com/ides3rt/colemak-dhk'
	git clone "$URL" || Err 1 'Failed to use `git clone`...'

	Basedir="${URL##*/}"/src
fi

if ((UID)); then

	Err 0 "For console and xkb installation run $Program(1) as root..."

	File="$Basedir"/colemak-dhk.xmodmap
	Dest="$HOME"/.Xmodmap

	if [[ -f $Dest ]]; then
		Err 0  "'$Dest' detected. creating a backup for '$Dest'..."
		mv "$Dest" "$Dest".bak || Err 1 "Failed to create backup for '$Dest'. aborted..."
	fi

	[[ -f $File ]] || Err 1 "'$File' is missing. aborted..."

	cp "$File" "$Dest" || Err 1 'Installation failed...'

else

	Err 0 "For xmodmap installation run $Program(1) as normal user..."

	type -P gzip &>/dev/null || Err 1 'gzip(1) is required for console installation...'

	Xkbdir="$Basedir"/xkb
	Xkbdest=/usr/share/X11/xkb

	Console="$Basedir"/colemak-dhk.map
	Consdest=/usr/share/kbd/keymaps/i386/colemak-dhk

	for Dest in "$Xkbdest"/{rules/evdev.xml,symbols/us} \
		"$Consdest"/"${Console##*/}"
	{
		[[ -d $Dest ]] && Err 1 "'$Dest' is a directory. aborted..."
		[[ -f $Dest ]] || Err 0  "'$Dest' detected. creating a backup for '$Dest'..."
		mv "$Dest" "$Dest".bak || Err 1 "Failed to create backup for '$Dest'. aborted..."
	}

	for File in "$Xkbdir"/{us,evdev.xml} "$Console"; {
		[[ -f "$File" ]] || Err 1  "'$File' is missing. aborted..."
	}

	if ! cp "$Xkbdir"/us "$Xkbdest"/symbols/us; then
		Err 0 "Installation of 'xkb/us' failed..."
		(( ErrCount++ ))
	fi

	if ! cp "$Xkbdir"/evdev.xml "$Xkbdest"/rules/evdev.xml; then
		Err 0 "Installation of 'xkb/evdev.xml' failed..."
		(( ErrCount++ ))
	fi

	if ! { mkdir -p "$Consdest" && \
			gzip -k "$Console" && \
			mv "$Console".gz "$Consdest"
		}
	then
		Err 0 "Installation of '${Console##*/}' failed..."
		(( ErrCount++ ))
	fi

	Err 0 "Installation is done with ${ErrCount:-0} error(s)..."

fi