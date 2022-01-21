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
"  mmmmmmmmm
"   l     l
"   l ### l
"   l  '  l
"   l  '  l
"   l#####l
"  mmmmmmmmm
"
" @Overview
"
"  This plugin allow to track time. You can choose various settings like
"  formats and rounding. See the following documentation for more details.
"
"  Note : you need to restart Vim if you change settings
"
" @Examples
"  A timespent report (rounded to 15 minutes):
"  1 h 15 || 20:03:01 -> 20:12:11 | 23:01:11 -> 23:59:59 |
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

" @command TimeSpentUpdate
" update duration (with last format known)
command! -range TimeSpentUpdate silent call s:update_multi_timespent(<line1>, <line2>)

" @command TimeSpentNext
" Jump to next timespent
command! TimeSpentNext silent call s:next_timespent(line('.'), 1)

" @command TimeSpentPrev
" Jump to previous timespent
command! TimeSpentPrev silent call s:next_timespent(line('.'), -1)

" @command TimeSpentFinalize
" Finalize timespent (e.g. for mark it as reported)
command! -range TimeSpentFinalize silent call s:finalise_timespent(<line1>, <line2>)

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


" @global g:timespentDateRounding
" For a date (checkpoint), precise the rounding mode : second, minute, 5-minutes
" default : 'second'
let s:datetimeDateRounding=get(g:, 'timespentDateRounding', 'second')

" @global g:timespentTimeRounding
" For the time spent, precise the rounding mode : second, minute, 5-minutes, 15-minutes
" default : 'second'
let s:datetimeTimeRounding=get(g:, 'timespentTimeRounding', 'second')

" @global g:timespentTimeRoundingAtLeastFor_1_minute
" Precise the minimal time in seconds to declare 1 min
" default : 30
let s:datetimeRounding1min=get(g:, 'timespentTimeRoundingAtLeastFor_1_minute', 30)

" @global g:timespentTimeRoundingAtLeastFor_5_minutes
" Precise the minimal time in seconds to declare 5 min
" default : 120
let s:datetimeRounding5min=get(g:, 'timespentTimeRoundingAtLeastFor_5_minutes', 120)

" @global g:timespentTimeRoundingAtLeastFor_15_minutes
" Precise the minimal time in seconds to declare 15 min
" default : 300
let s:datetimeRounding15min=get(g:, 'timespentTimeRoundingAtLeastFor_15_minutes', 300)

" @global g:timespentTimeTakingTime
" In seconds, time for marking time
" default : 0
let s:timeTakingSeconds=get(g:, 'timespentTimeTakingTime', 0)

" FIXME TODO ?
"" " @global g:timespentFinaliseDateFormat
"" " Compact the timespent (e.g. for marking it as reported)
"" " Time format using %H %M %S in groups {{total}} {{day}}, {{duration}}, {{timestamps}}
"" " default : {{total %H:%M:%S}} {{totalsep |=}} {{day %Y%m%d}} {{timestamps %H:%M:%S}} {{sep |}}
"let s:finaldatetimeFormat=get(g:, 'timespentFinalizeDateFormat',
"      \ '(timestamps) %H:%M:%S')

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
from math import trunc
 
formatstr = vim.eval("s:datetimeFormat")
rounding = vim.eval("s:datetimeTimeRounding")
sep = vim.eval("s:timeUnionMarker")
min_sec_minute = int(vim.eval("s:datetimeRounding1min"))
min_sec_5minutes = int(vim.eval("s:datetimeRounding5min"))
min_sec_15minutes = int(vim.eval("s:datetimeRounding15min"))
_unitformat = None
_hourformat = None
_minuteformat = None
_secondformat = None

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

if rounding == 'second':
  pass
elif rounding == 'minute':
  minute_rounding = trunc(seconds/60)*60
  if (minute_rounding + min_sec_minute) <= seconds:
    seconds = minute_rounding + 60
  else:
    seconds = minute_rounding
elif rounding == 'hour-ratio':
  # -- obsolete / meaningless --
  # attempt to approximates to minutes 0, 6, 12, 18, 24, 30, 36, 42, 48, 54
  remains=(seconds%3600)
  _remains=(remains/360)
  seconds -= remains
  for i in range(9, -1, -1):
    if _remains > (i + .25):
      if _remains > (i + .5):
        seconds += (i+1) * 360
      else: # align on 3 9 15 21 27 33 39 45 51 57
        seconds += (i+0.5) * 360
      break
elif rounding == '5-minutes':
  minute_rounding = trunc(seconds/300)*300
  if (minute_rounding + min_sec_5minutes) <= seconds:
    seconds = minute_rounding + 300
  else:
    seconds = minute_rounding
elif rounding == '15-minutes':
  minute_rounding = trunc(seconds/900)*900
  if (minute_rounding + min_sec_15minutes) <= seconds:
    seconds = minute_rounding + 900
  else:
    seconds = minute_rounding

unitformat = _unitformat or '%.2f'

if ('%H:%M' in res) or ('%H%M' in res):
  hourformat = '%02d'
  minuteformat = '%02d'
  secondformat = '%02d'
elif '%M' in res:
  hourformat = '%d'
  if '%H' in res:
    minuteformat = '%02d'
  else:
    minuteformat = '%d'
  secondformat = '%d'
else:
  hourformat = unitformat
  minuteformat = unitformat
  secondformat = '%d'

# allow override
if _hourformat:
  hourformat = _hourformat
if _minuteformat:
  minuteformat = _minuteformat

if '%H' in res.upper():
  hours=seconds/3600
  seconds%=3600

  res = res.replace('%h', unitformat % hours)
  res = res.replace('%H', hourformat % hours)

if '%M' in res.upper():
  minutes=seconds/60
  seconds%=60
  res = res.replace('%m', unitformat % minutes)
  res = res.replace('%M', minuteformat % minutes)
res = res.replace('%S', secondformat % seconds)

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

fu! s:get_localtime(end)
  let l:ret = localtime()
  if !a:end
     let l:ret -= s:timeTakingSeconds
  endif
  if s:datetimeDateRounding == 'minute'
     if a:end 
       let l:ret += 60 - s:datetimeRounding1min
     endif
     let l:minute_rounding = trunc(l:ret/60)*60
     if (l:minute_rounding + s:datetimeRounding1min) <= l:ret
        let l:ret = float2nr(l:minute_rounding + 60)
     else
       let l:ret = float2nr(l:minute_rounding)
    endif
  elseif s:datetimeDateRounding == '5-minutes'
     if a:end 
       let l:ret += 300 - s:datetimeRounding5min
     endif
     let l:minute_rounding = trunc(l:ret/300)*300
     if (l:minute_rounding + s:datetimeRounding5min) <= l:ret
        let l:ret = float2nr(l:minute_rounding + 300)
     else
        let l:ret = float2nr(l:minute_rounding)
    endif
  endif
  return l:ret
endfu

fu! s:close_timespent(i)
   let l:l=getline(a:i)
   let l:curtime=strftime(s:datetimeFormat, s:get_localtime(1))
   if l:l =~ s:timeStartTo.'$'
      exe a:i.'s/$/'.l:curtime.s:timeSeparatorSpaced.'/'
   endif
   call s:update_timespent(a:i)
endfu

fu! s:finalise_timespent(start, end)
  for l:i in range(a:start, a:end)
    let l:l=getline(l:i)
    if l:l =~ s:timeStartToEnd.s:timeSeparatorRe
      call s:close_timespent(l:i)
      exe l:i.'s/'.s:timeTotalSeparator.'/=/'
      exe l:i.'s/'.s:timeSeparator.'/;/g'
    endif
  endfor
endfu

fu! s:update_multi_timespent(start, end)
   for l:i in range(a:start, a:end)
    let l:l=getline(l:i)
    if l:l =~ s:timeStartToEnd.s:timeSeparatorRe
      call s:update_timespent(l:i)
    endif
  endfor
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
  if l:l =~ s:timeStartTo.'$'
    let l:curtime = strftime(s:datetimeFormat, s:get_localtime(1))
    exe a:i.'s/\s*$/ '.l:curtime.s:timeSeparatorSpaced.'/'
  elseif a:extend && l:l =~ s:timeToEnd.s:timeSeparatorRe.'$'
    let l:curtime = strftime(s:datetimeFormat, s:get_localtime(0))
    exe a:i.'s/'.s:timeToEnd.s:timeSeparatorRe.'\s*$/'.s:timeUnionMarkerSpaced.l:curtime.s:timeSeparatorSpaced.'/'
  elseif l:l =~ s:timeToEnd.s:timeSeparatorRe.'$' || l:l =~ s:timeTotalSeparator
    let l:curtime = strftime(s:datetimeFormat, s:get_localtime(0))
    exe a:i.'s/\s*$/ '.l:curtime.s:timeUnionMarkerSpaced.'/'
  else
    let l:curtime = strftime(s:datetimeFormat, s:get_localtime(0))
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

