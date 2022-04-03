vim9script
command -bang -nargs=? -complete=customlist,synfo#Complete Synfo synfo#Cmd(<bang>0, <f-args>)
