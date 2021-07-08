" timespent.vim -- Vim tool for fast time tracking
" @Author:      luffah (luffah AT runbox com)
" @License:     AGPLv3 (see https://www.gnu.org/licenses/agpl-3.0.txt)
" @Created:     2020-12-11
" @Last Change: 2020-12-12
" @Revision:    1
" @Files
"   ./timespent/convert/timewarrior.vim
"
" @AsciiArt
"
"  A timespent report :
"  03:56:58 || 20200301 20:03:01 -> 20200301 20:12:11 | 20201211 20:12:11 -> 20201211 23:59:59 |
"
" @command TimeSpentAdd
" add datetime on current line.
" (jump to next line with a different content is found)
command! TimeSpentAdd call s:add_timespent(line('.'), 0)

" @command TimeSpentExtend
" extend datetime on current line.
" (jump to next line with a different content is found)
command! TimeSpentExtend call s:add_timespent(line('.'), 1)

" @command TimeSpentClose
" add end datetime (if not found) on current line and
" update duration.
command! TimeSpentClose silent call s:close_timespent(line('.'))

" @command TimeSpentStop
" close all timespent lines of the current file
command! TimeSpentStop silent call s:close_timespent_all()


" @command FinalizeSpentStop
" Jump to next timespent
command! TimeSpentNext silent call s:next_timespent(line('.'), 1)

" @command FinalizeSpentStop
" Jump to previous timespent
command! TimeSpentPrev silent call s:next_timespent(line('.'), -1)

" @command FinalizeSpentStop
" Finalize timespent (e.g. for mark it as reported)
command! TimeSpentFinalize silent call s:finalise_timespent(line('.'))

" @global g:timespentDateFormat
" Date/time format using %y %Y %m %d %H %M %S
" default : %Y%m%d  %H:%M:%S
let s:datetimeFormat=get(g:, 'timespentDateFormat', '%Y%m%d %H:%M:%S')

" @global g:timespentTimeFormat
" Total time format using %H %M %S
" default : %H:%M:%S
"
"     %Ss  If you want to see seconds only
"     590s || 20200301 20:03:01 -> 20200301 20:12:51 |
"     %H   If you want to see hours only, you shall know the value is truncated
"     0 || 20200301 20:03:01 -> 20200301 20:52:51 |
let s:timeFormat=get(g:, 'timespentTimeFormat', '%H:%M:%S')

" FIXME TODO ?
"" " @global g:timespentFinaliseDateFormat
"" " Compact the timespent (e.g. for marking it as reported)
"" " Time format using %H %M %S in groups {{total}} {{day}}, {{duration}}, {{timestamps}}
"" " default : {{total %H:%M:%S}} {{totalsep |=}} {{day %Y%m%d}} {{timestamps %H:%M:%S}} {{sep |}}
"let s:finaldatetimeFormat=get(g:, 'timespentFinalizeDateFormat',
"      \ '(timestamps) %H:%M:%S')

let s:timeFormat=get(g:, 'timespentTimeFormat', '%H:%M:%S')
let s:datetimeFormatRe=substitute(substitute(s:datetimeFormat, '%[HMSmdy]\C', '\\d\\d', 'g'), '%Y', '\\d\\d\\d\\d', '')
let s:timeFormatRe=substitute(s:timeFormat, '%[HMSmdy]\C', '\\d\\d', 'g')
let s:timeSeparator='|'
let s:timeSeparatorSpaced=' '.s:timeSeparator.' '
let s:timeSeparatorRe='\s*'.s:timeSeparator.'\s*'
let s:timeTotalSeparator='||'
let s:timeTotalSeparatorSpaced=' '.s:timeTotalSeparator.' '
let s:timeTotalSeparatorRe='\s*'.s:timeTotalSeparator.'\s*'
let s:timeUnionMarker='->'
let s:timeUnionMarkerSpaced=' '.s:timeUnionMarker.' '
let s:timeUnionMarkerRe='\s*'.s:timeUnionMarker.'\s*'
let s:timeStartTo=s:datetimeFormatRe.s:timeUnionMarkerRe
let s:timeStartToEnd=s:datetimeFormatRe.s:timeUnionMarkerSpaced.s:datetimeFormatRe
let s:timeToEnd=s:timeUnionMarkerSpaced.s:datetimeFormatRe

fu! s:update_timespent(i)
  let l:l=getline(a:i)
  if l:l =~ s:timeStartToEnd.s:timeSeparatorRe
      " cant't figure how to properly get list of elems corresponding to
      " matchlist, so just cleaning 
      let l:ts = matchlist(l:l, '\('.s:timeStartToEnd.s:timeSeparatorRe.'\)\+')[0]
      let l:ts = substitute(l:ts, s:timeSeparatorRe.'$', '', '')
      let l:ts = substitute(l:ts, s:timeSeparatorRe, s:timeSeparatorSpaced, 'g')
      let l:ts = split(l:ts, ' | ')
python3 << EOF
import vim
import datetime
 
formatstr = vim.eval("s:datetimeFormat")
sep = vim.eval("s:timeUnionMarker")

def time_between(d1, d2):
    d1 = datetime.datetime.strptime(d1, formatstr)
    d2 = datetime.datetime.strptime(d2, formatstr)
    return (d2 - d1)

total = datetime.timedelta(0)
for i in list(vim.eval("l:ts")):
    try:
        [a, b] = i.split(sep)
        if a and b:
            total += time_between(a.strip(), b.strip())
    except Exception as e:
        continue

res = vim.eval("s:timeFormat")
seconds=total.total_seconds()
if '%H' in res:
  hours=seconds/3600
  seconds%=3600
  res = res.replace('%H', '%02d' % hours)
if '%M' in res:
  minutes=seconds/60
  seconds%=60
  res = res.replace('%M', '%02d' % minutes)
res = res.replace('%S', '%02d' % seconds)

res = vim.eval("s:timeFormat").replace('%H', '%02d' % hours).replace('%M', '%02d' % minutes).replace('%S', '%02d' % seconds)
vim.command("let sTotalDuration = '%s'" % res)
EOF
    let s:total = sTotalDuration
    unlet sTotalDuration
    if l:l =~ s:timeTotalSeparatorRe
      exe a:i.'s/^\(\D*\)\(.*\)'.s:timeTotalSeparatorRe.'\('.s:datetimeFormatRe.'\)/\1'.s:total.s:timeTotalSeparatorSpaced.'\3/'
    else
      exe a:i.'s/^\(\D*\)/\1'.s:total.s:timeTotalSeparatorSpaced.'\2/'
    endif
  endif
endfu

fu! s:close_timespent_all()
  for l:i in range(1,line('$'))
    call s:close_timespent(l:i)
  endfor
endfu

fu! s:close_timespent(i)
   let l:l=getline(a:i)
   let l:curtime=strftime(s:datetimeFormat)
   if l:l =~ s:timeStartTo.'$'
      exe a:i.'s/$/'.l:curtime.s:timeSeparatorSpaced.'/'
   endif
   call s:update_timespent(a:i)
endfu

fu! s:finalise_timespent(i)
    call s:close_timespent(a:i)
    exe a:i.'s/'.s:timeTotalSeparator.'/=/'
    exe a:i.'s/'.s:timeSeparator.'/;/g'
endfu

fu! s:next_timespent(i, step)
  "find a line matching the pattern
  let l:i = a:i
  let l:e=line('$')
  while l:i > 0 && l:i <= l:e && getline(l:i) !~ s:timeStartToEnd.s:timeSeparatorRe
    let l:i+=a:step
  endwhile
  if l:i != l:e
    exe l:i
  endif
endfu

fu! s:add_timespent(i, extend)
  let l:i=a:i
  let l:l=getline(a:i)
  let l:curtime=strftime(s:datetimeFormat)
  if l:l =~ s:timeStartTo.'$'
    exe a:i.'s/\s*$/ '.l:curtime.s:timeSeparatorSpaced.'/'
  elseif a:extend && l:l =~ s:timeToEnd.s:timeSeparatorRe.'$' 
    exe a:i.'s/'.s:timeToEnd.s:timeSeparatorRe.'\s*$/'.s:timeUnionMarkerSpaced.l:curtime.s:timeSeparatorSpaced.'/'
  elseif l:l =~ s:timeToEnd.s:timeSeparatorRe.'$' || l:l =~ s:timeTotalSeparator
      exe a:i.'s/\s*$/ '.l:curtime.s:timeUnionMarkerSpaced.'/'
  else
    if l:l =~ '^\W*$'
      exe a:i.'s/^\(\W*\)/\1'.l:curtime.s:timeUnionMarkerSpaced.'/'
    elseif synIDattr(synIDtrans(synID(line("."), col("$")-1, 1)), "name") =~? 'comment'
      exe a:i.'norm o '
      let l:i+=1
      exe l:i.'s/^\(\W*\) \(.*\|$\)/\1'.l:curtime.s:timeUnionMarkerSpaced.'\2/'
    else
      let l:indent = strpart(l:l, 0, match(l:l, '\S'))
      call append(l:i, l:indent.l:curtime.s:timeUnionMarkerSpaced)
      let l:i+=1
    endif
  endif
  call s:update_timespent(l:i)
endfu

" Utilities
"
" @function timespent#ftime(year,month,day,hours,minutes,seconds)
" return formatted date as specified in |g:timespentDateFormat|
"
fu! timespent#ftime(year,month,day,hours,minutes,seconds)
    let l:ret=s:datetimeFormat
    let l:ret=substitute(l:ret,'%Y', printf("%04d", a:year), '')
    let l:ret=substitute(l:ret,'%y', printf("%02d", a:year % 100), '')
    let l:ret=substitute(l:ret,'%m', printf("%02d", a:month), '')
    let l:ret=substitute(l:ret,'%d', printf("%02d", a:day), '')
    let l:ret=substitute(l:ret,'%H', printf("%02d", a:hours), '')
    let l:ret=substitute(l:ret,'%M', printf("%02d", a:minutes), '')
    let l:ret=substitute(l:ret,'%S', printf("%02d", a:seconds), '')
    return l:ret
endfu

