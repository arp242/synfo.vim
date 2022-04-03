Synfo.vim prints information about Vim syntax highlighting and text properties.

This is useful to know *why* something has the highlighting that it does.
Especially for plugin or syntax file authors it can be quite useful.

There is one command: `:Synfo`, which takes any of the following as an argument:

    syntax      List syntax items for whatever is under the cursor.
    props       List text properties for whatever is under the cursor.
    types       List all defined text property types, both global ones and
                buffer-local ones (buffer-local types are prefixed with `(b)`).

You can shorten them all: `s`, `syn`, etc. are identical to `syntax`.

For example `:Synfo t p` will list all property types, followed by the
properties of whatever is under the cursor.

The default if you just type `:Synfo` is `syntax props`.

---

*Note*: you will need a fairly recent Vim for the text properties to work;
specifically, Vim [8.3.3233](https://github.com/vim/vim/pull/8647). The syntax
stuff will work for older versions too, although you'll still need something
fiarly recent as it uses Vim9Script.
