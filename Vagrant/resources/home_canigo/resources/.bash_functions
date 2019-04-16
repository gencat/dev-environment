cd_func () {
    # amb la comanda "cd-" podem tornar al directori previ
	pushd .>/dev/null

	[ $# -eq 0 ] && cd ~ && return $?

	cd "$1" || return $?

	# Es un directorio de Git?
	[ -d .git ] && git status && echo '--' && return 0

	# té final de barra (auto-completat?)
	echo "$1" | grep -q '/$' || return 0

	[ `basename $PWD` = 'Downloads' ] && ll -rt && return 0
	[ "$PWD" = '/tmp' ] && ll -rt && return 0

	l

	return 0
}
unalias cd 2> /dev/null
alias cd=cd_func
