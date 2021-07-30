vim9script

def synfo#Cmd(bang: bool, ...types: list<string>)
	for t in (len(types) > 0 ? types : ['s', 'p'])
		if t =~ '^t\%[ypes]$'
			ListTypes()
		elseif t =~ '^s\%[yntax]$'
			ListSyntax(bang)
		elseif t =~ '^p\%[rops]$'
			ListProps(bang)
		else
			echohl ErrorMsg
			echom 'synfo.vim: unknown argument: ' .. t
			echohl None
		endif
	endfor
enddef

def ListSyntax(bang: bool)
	var syn = synstack(line('.'), col('.'))->mapnew((_, id) => synIDattr(id, 'name'))
	if len(syn) == 0
		return
	endif

    echo 'Syntax items (lowest priority first):'
	for s in syn
		# TODO: get text. There isn't really a good way of doing this it seems.
		var text = 'xxx'

		echo printf('    %-15s ', s)
		Echonhl(s, text)
		EchonHighlight(s)
	endfor
enddef

def ListProps(bang: bool)
	var props = prop_list(line('.'))
		->filter((_, v) => v.col <= col('.') && v.col + v.length >= col('.'))
		->mapnew((_, v) => [v, prop_type_get(v.type, {bufnr: v.type_bufnr})])
	if len(props) == 0
		return
	endif

	echo 'Properties:'
	for p in props
		var hl   = get(p[1], 'highlight', 'Normal')
        var text = getline('.')[p[0].col - 1 : p[0].col + p[0].length - 2]
		if len(text) > 30
			text = text[: 15] .. '…' .. text[-15 :]
		elseif text == ''
			text = 'xxx'
		endif

		echo printf('    %-20s |', p[0].type)
		Echonhl(hl, text)
		echon '|'
		echon repeat(' ', 21 - len(text))
		EchonHighlight(hl)
	endfor
enddef

def ListTypes()
	var types = []
	for a in [{}, {bufnr: bufnr('')}]  # List both globals and buffer-local.
		types->extend(prop_type_list(a)->mapnew((_, v) =>
			prop_type_get(v, a)->extend({name: v})))
	endfor
	if len(types) == 0
		echom 'No property types defined'
		return
	endif

	types->sort((a, b) => a.name == b.name ? 0 : a.name > b.name ? 1 : -1)
	echo printf('    %-24s %-14s', 'Prop name', 'Vim hl')
	for t in types
		var hl = t->get('highlight', '-')

		echo printf('%-28s %-14s', ((t.bufnr > 0 ? '(b) ' : '') .. t.name), hl)
		if hl == '-'
			echon 'no highlight defined'
		else
			Echonhl(hl, 'xxx')
			EchonHighlight(hl)
		endif
	endfor
enddef

# Echo properties for a highlight group.
def EchonHighlight(name: string)
	var id = synIDtrans(hlID(name))

	# There isn't any function to get this as far as I can see. hlID() gets the
	# "real" ID, but synIDtrans() will resolve links. There isn't really
	# anything else that accepts a highlight ID.
	var link = []
	var linkname = name
	while true
		var h = execute(':hi ' .. linkname)
		if h !~ ' links to '
			break
		endif
		linkname = h[strridx(h, ' ') + 1 :]
		add(link, linkname)
	endwhile

	var props = []
	# TODO: this doesn't seem quite correct; it lists "gui=bold", but it's not
	# actually in bold (with termguicolors) – looks like that only applies to
	# the "real" GUI and not "termguicolors"?
	# Disable it for now.
	# for p in ['bold', 'italic', 'reverse', 'inverse', 'standout', 'underline', 'undercurl', 'strike']
	# 	if synIDattr(id, p) == '1'
	# 		props->add(p)
	# 	endif
	# endfor

	var fg = synIDattr(id, 'fg#')
	var bg = synIDattr(id, 'bg#')
	if fg != ''
		# TODO: this should use the correct *fg=
		exe 'hi SynfoTmp guifg=' .. synIDattr(id, 'fg#')
		echon ' fg='
		echohl SynfoTmp
		echon synIDattr(id, 'fg#')
		echohl None
		hi clear SynfoTmp
	endif
	if bg != ''
		# TODO: this should use the correct *bg=
		exe 'hi SynfoTmp guibg=' .. synIDattr(id, 'bg#')
		echon ' bg='
		echohl SynfoTmp
		echon synIDattr(id, 'bg#')
		echohl None
		hi clear SynfoTmp
	endif

	# TODO: also add the actual text:
	#   goStruct        xxx |struct {..}| fg=#af5f00 links to Keyword, Statement
    #   goType          xxx |string|      fg=#00cd00 links to Type
	#
	# Inside |...| to show leading/trailing whitespace (although, maybe just
	# replace those with a ␣?)
	# U+2400..U+241F
	# U+2421: U+2424
	# Also think about tabs.

	if len(props) > 0
		echon props->join(' ')
		echon '  '
	endif
	if len(link) > 0
		echon ' links to ' .. link->join(', ')
	endif
enddef

# Echon with a highlight group applied.
def Echonhl(group: string, msg: string, ...args: list<string>)
	exe 'echohl' group
	echon call('printf', [msg] + args)
	echohl None
enddef

defcompile

