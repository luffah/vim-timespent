" timespent.vim -- Vim tool for fast time tracking
" @Author:      luffah (luffah AT runbox com)
" @License:     AGPLv3 (see https://www.gnu.org/licenses/agpl-3.0.txt)
" @Created:     2020-12-11
" @Last Change: 2020-12-11
" @Revision:    1
"
" @AsciiArt
"
"  A timespent report :
"  03:56:58 || 20200301 20:03:01 -> 20200301 20:12:11 | 20201211 20:12:11 -> 20201211 23:59:59 |
"
" @command AddTimeSpent
" add/update datetime on current line.
" (jump to next line with a different content is found)
command! AddTimeSpent call s:add_timespent(line('.'))

" @command CloseTimeSpent
" add end datetime (if not found) on current line and
" update duration.
command! CloseTimeSpent silent call s:close_timespent(line('.'))

" @command StopTimeSpentAll
" apply CloseTimeSpent on all lines of the current file
command! StopTimeSpentAll silent call s:close_timespent_all()

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
python << EOF
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
    except:
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

fu! s:add_timespent(i)
  let l:i=a:i
  let l:l=getline(a:i)
  let l:curtime=strftime(s:datetimeFormat)
  if l:l =~ s:timeStartTo.'$'
    exe a:i.'s/\s*$/ '.l:curtime.s:timeSeparatorSpaced.'/'
  elseif l:l =~ s:timeToEnd.s:timeSeparatorRe.'$' || l:l =~ s:timeTotalSeparator
    exe a:i.'s/$/'.l:curtime.s:timeUnionMarkerSpaced.'/'
  else
    if l:l =~ '^\W*$'
      exe a:i.'s/^\(\W*\)/\1'.l:curtime.s:timeUnionMarkerSpaced.'/'
    else
      exe a:i.'s/^\(\W*\)\(.*\)/\1\2\r\1'.l:curtime.s:timeUnionMarkerSpaced.'/'
      let l:i+=1
    endif
  endif
  call s:update_timespent(l:i)
endfu
