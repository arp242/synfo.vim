vim9script

export def Cmd(bang: bool, ...types: list<string>)
	for t in (len(types) > 0 ? types : ['s', 'p'])
		if t =~ '^t\%[ypes]$'
			ListTypes()
		elseif t =~ '^h\%[ighlights]$'
			ListHighlights()
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

export def Complete(lead: string, cmdlind: string, pos: number): list<string>
    return ['types', 'highlights', 'props', 'syntax']->sort()
        ->filter((_, v) => strpart(v, 0, len(lead)) == lead)
enddef

# List syntax items.
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

# List text properties.
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

		echo printf('    %-20s │', p[0].type)
		Echonhl(hl, text)
		echon '│'
		echon repeat(' ', 21 - len(text))
		EchonHighlight(hl)
	endfor
enddef

# List all types.
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

	# TODO: be smarter about column sizes.
	types->sort((a, b) => a.name == b.name ? 0 : a.name > b.name ? 1 : -1)
	echo printf('    %-24s %-24s', 'Prop name', 'Vim hl')
	for t in types
		var hl = t->get('highlight', '-')

		echo printf('%-28s %-24s', ((t.bufnr > 0 ? '(b) ' : '') .. t.name), hl)
		if hl == '-'
			echon 'no highlight defined'
		else
			Echonhl(hl, 'xxx')
			EchonHighlight(hl)
		endif
	endfor
enddef

var vimstyles = ['SpecialKey', 'EndOfBuffer', 'NonText', 'Directory',
                 'ErrorMsg', 'IncSearch', 'Search', 'MoreMsg', 'ModeMsg',
                 'LineNr', 'LineNrAbove', 'LineNrBelow', 'CursorLineNr',
                 'Question', 'StatusLine', 'StatusLineNC', 'VertSplit', 'Title',
                 'Visual', 'VisualNOS', 'WarningMsg', 'WildMenu', 'Folded',
                 'FoldColumn', 'DiffAdd', 'DiffChange', 'DiffDelete',
                 'DiffText', 'SignColumn', 'Conceal', 'SpellBad', 'SpellCap',
                 'SpellRare', 'SpellLocal', 'Pmenu', 'PmenuSel', 'PmenuSbar',
                 'PmenuThumb', 'TabLine', 'TabLineSel', 'TabLineFill',
                 'CursorColumn', 'CursorLine', 'ColorColumn', 'QuickFixLine',
                 'StatusLineTerm', 'StatusLineTermNC', 'MatchParen',
                 'ToolbarLine', 'ToolbarButton',

                 # Stuff from plugins I use.
                 'PianoPopup', 'PianoFeedback',
                 'DirvishSuffix', 'DirvishPathTail', 'DirvishArg',
                 'lscDiagnosticError', 'lscDiagnosticWarning', 'lscDiagnosticInfo',
                 'lscDiagnosticHint', 'lscReference', 'lscCurrentParameter',
]

# list all highligt groups, like ":hi", but in the same style as the other
# commands and filter out vim stuff.
def ListHighlights()
	# TODO: improve and actually format.
	var hi = execute(':hi')->split('\n')->filter((_, v) => vimstyles->index(v[: v->stridx(' ') - 1]) == -1 )
	echo hi->join("\n")
enddef

var attr_def = {bold:     'b',  italic:    'i',  reverse:   'r',  inverse: 'in',
                standout: 'so', underline: 'ul', undercurl: 'uc', strike: 'st'}

# :echon properties for a highlight group.
def EchonHighlight(name: string)
	var id = synIDtrans(hlID(name))

	# TODO: this doesn't seem quite correct; it lists "gui=bold", but it's not
	# actually in bold (with termguicolors) – looks like that only applies to
	# the "real" GUI and not "termguicolors"?
	var props = 0
	echon '  '
	for [k, v] in attr_def->items()
		if synIDattr(id, k) == '1'
			exe 'hi SynfoTmp gui=' .. k
			echohl SynfoTmp
			echon v
			echohl None

			props += len(v)
		endif
	endfor
	echon repeat(' ', 6 - props)

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
		link->add(linkname)
	endwhile
	if len(link) > 0
		echon '  → links to ' .. link->join(', ')
	endif
enddef

# :echon with a highlight group applied.
def Echonhl(group: string, msg: string, ...args: list<string>)
	exe 'echohl' group
	echon call('printf', [msg] + args)
	echohl None
enddef

defcompile

