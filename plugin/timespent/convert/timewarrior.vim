" @function timespent#convert#timewarrior#from_data()
" Allow to import timewarrior datas with a copy/paste.
" Select the datas, and type :call timespent#convert#timewarrior#from_data()
" and the datas will take the format used by the timespent tool.
" 
fu! timespent#convert#timewarrior#from_data() range
  let l:lines=getline(a:firstline, a:lastline)
  norm gvd
  let l:newlines=s:convert_from_timewarrior_data(l:lines)
  call append(a:firstline,l:newlines)
endfu

fu! s:convert_from_timewarrior_data(lines)
  let l:taskdict={}
  for l:l in a:lines
    let l:task=substitute(l:l, '^[^#]\+ # \(.*\)$', '\1','')
    let l:timeS=matchlist(l:l, '\(\d\d\d\d\)\(\d\d\)\(\d\d\)T\(\d\d\)\(\d\d\)\(\d\d\)Z - \d\d\d\d\d\d\d\dT\d\d\d\d\d\dZ')
    let l:timeE=matchlist(l:l, '\d\d\d\d\d\d\d\dT\d\d\d\d\d\dZ - \(\d\d\d\d\)\(\d\d\)\(\d\d\)T\(\d\d\)\(\d\d\)\(\d\d\)Z')
    if !(len(l:timeS) && len(l:timeE))
      continue
    endif
    let l:start=s:ftime(str2nr(l:timeS[1]),str2nr(l:timeS[2]),str2nr(l:timeS[3]),str2nr(l:timeS[4]),str2nr(l:timeS[5]),str2nr(l:timeS[6]))
    let l:end=s:ftime(str2nr(l:timeE[1]),str2nr(l:timeE[2]),str2nr(l:timeE[3]),str2nr(l:timeE[4]),str2nr(l:timeE[5]),str2nr(l:timeE[6]))
    if !has_key(l:taskdict, l:task)
      let l:taskdict[l:task] = ''
    endif 
    let l:taskdict[l:task] .= l:start.s:timeUnionMarkerSpaced.l:end.s:timeSeparatorSpaced
  endfor
  let l:ret=[]
  for l:t in keys(l:taskdict)
      call add(l:ret, l:t)
      call add(l:ret, taskdict[l:t])
  endfor
  return l:ret
endfu
