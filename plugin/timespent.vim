" timespent.vim -- Vim tool for fast time tracking
" @Author:      luffah (luffah AT runbox com)
" @License:     AGPLv3 (see https://www.gnu.org/licenses/agpl-3.0.txt)
" @Created:     2020-12-11
" @Last Change: 2022-01-25
" @Revision:    2
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
"  Note : you need write setting in vimrc file and to restart Vim to apply
"
" @Examples
"
" (In theses example the timesheet are written a .txt file )
"
" Setup your keys (some may appear useless to you, feel free to change keys):
"   (vimrc)
"   " to see the current <leader>, use : let mapleader
"
"   nnoremap <leader>r      :TimeSpentAdd<Cr>
"   nnoremap <leader><C-r>  :TimeSpentExtend<Cr>
"   nnoremap <leader>R      :TimeSpentClose<Cr>
"   nnoremap <leader>f      :TimeSpentFinalize<Cr>
"   vnoremap <leader>f      :TimeSpentFinalize<Cr>
"   nnoremap <leader>F      :TimeSpentUnFinalize<Cr>
"   vnoremap <leader>F      :TimeSpentUnFinalize<Cr>
"   nnoremap <leader><C-n>  :TimeSpentNext<Cr>
"   nnoremap <leader><C-p>  :TimeSpentPrevious<Cr>
"   nnoremap <leader><C-o>  :TimeSpentJumpOpenned<Cr>
"
"
" If you put your timesheets in a text file, it will look like:
"   (Text file)
"   01:08:10 || 20220125 20:03:01 -> 20220125 20:12:11 | 20220125 23:00:00 -> 20220125 23:59:00 |
"
" You may discover that you never start the timer before writing task title.
"
" To define how many seconds it takes for you to write the title of a task :
"   (vimrc)
"   let g:timespentTimeTakingTime = 30
"
" You may want to round time to 15 minutes.
"   (Text file)
"   1 h 15 || 20220125 20:03:01 -> 20220125 20:12:11 | 20220125 23:00:00 -> 20220125 23:59:00 |
"
" To setup that:
"   (vimrc)
"   let g:timespentTimeRounding = '15-minutes'  " or 5-minutes
"   let g:timespentTimeFormat = '%H h %M m'
"
" You may want to ignore seconds and round to 5 minute each item
"   (Text file)
"   1 h 15 || 20220125 20:00 -> 20220125 20:15 | 20220125 23:00 -> 20220226 00:00 |
"
" To setup that:
"   (vimrc)
"   let g:timespentDateRounding = '5-minutes'  " or minute
"   let g:timespentDateFormat = '%Y%m%d %H:%M'
"
" You may want to have in your statusline the total time done in the day.
" To not slow down you editor, let's do it when the buffer is written.
"
" To setup that:
"   (vimrc)
"   " (you may need to check :h statusline)
"   " (below, an example of how add the value)
"
"   fu TotalTimeToday()
"    return get(b:, 'total_time_today', '')
"   endfu
"
"   augroup StatuslineTimespent
"    au!
"    au BufWrite *.txt let b:total_time_today=timespent#total_time_today()
"   augroup END
"
"   set statusline+=%{TotalTimeToday()}
"
" To complete the introduction, you shall discover commands some too :
"   (Text file)
"   bla bla
"   part 1
"   1 h 15 || 20220125 20:03 -> 20220125 20:12 | 20220125 23:00 -> 20220125 23:59 |
"   part 2
"   0 h 10 m || 20220125 20:03 -> 20220125 20:12 |
"   part 3
"   0 h 10 m || 20220125 20:03 -> 20220125 20:12 |
"
"   (Commands)
"   " update time spent for 'part 2' (line nume is 5)
"   :5
"   :TimeSpentAdd
"   " By default, commands use current line
"   " but you can specify an address
"   :5TimeSpentExtend
"   :7TimeSpentExtend
"   " add a new time spent after 'bla bla'
"   :1TimeSpentAdd
"   " now a time report exist at line 2, you can add time to it
"   :2TimeSpentAdd
"   " jump between time spent
"   :TimeSpentNext
"   :TimeSpentPrevious
"   :TimeSpentJumpOpenned
"   " jump to first and last time spent (by line order)
"   :0TimeSpentNext
"   :$TimeSpentPrevious
"   " Mark timespent as closed
"   :2TimeSpentFinalize
"


" @command TimeSpentAdd
" add datetime on current line (or line number specified before).
" (jump to next line with a different content is found)
command! -range TimeSpentAdd silent call <SID>add_timespent(<line1>, 0)

" @command TimeSpentExtend
" extend datetime on current line (or line number specified before).
" (jump to next line with a different content is found)
command! -range TimeSpentExtend silent call s:add_timespent(<line1>, 1)

" @command TimeSpentClose
" add end datetime (if not found) on current line and
" update duration.
command! -range TimeSpentClose silent call s:close_timespent(<line1>)

" @command TimeSpentStop
" close all timespent lines of the current file
command! TimeSpentStop silent call s:close_timespent_all()

" @command TimeSpentUpdate
" update duration (with last format known)
command! -range TimeSpentUpdate silent call s:update_multi_timespent(<line1>, <line2>)

" @command TimeSpentUpdateTimeFormatFrom
" update timestamps from old format in parameter to new format known (from globals)
command! -range -nargs=+ TimeSpentUpdateTimeFormatFrom silent call s:update_multi_datetime_format(<line1>, <line2>, <q-args>)


" @command TimeSpentJumpOpenned
" Jump to any other timespent. (If used with a line number it will be included)
command! -range TimeSpentJumpOpenned silent call s:next_timespent(<line1>, 1, 1, 1)

" @command TimeSpentJumpLast
" Jump to the (chronologically) last timespent.
command! TimeSpentJumpLast silent call s:last_timespent()

" @command TimeSpentJumpBefore
" Jump to the (chronologically) before timespent.
command! TimeSpentJumpBefore silent call s:before_timespent()

" @command TimeSpentJumpAfter
" Jump to the (chronologically) after timespent.
command! TimeSpentJumpAfter silent call s:after_timespent()

" @command TimeSpentNext
" Jump to next timespent (If used with a line number it will be included)
command! -range TimeSpentNext silent call s:next_timespent(<line1>, 1)

" @command TimeSpentPrev
" Jump to previous timespent (If used with a line number it will be included)
command! -range TimeSpentPrevious silent call s:next_timespent(<line1>, -1)

" @command TimeSpentFinalize
" Finalize timespent (e.g. for mark it as reported)
command! -range TimeSpentFinalize silent call s:finalise_timespent(<line1>, <line2>)

" @command TimeSpentUnFinalize
" unFinalize timespent (e.g. for unmark it as reported) to allow updates
command! -range TimeSpentUnFinalize silent call s:unfinalise_timespent(<line1>, <line2>)

" @global g:timespentDateFormat
" Date/time format using %y %Y %m %d %H %M %S
" default : '%Y%m%d  %H:%M:%S'
let s:datetimeFormat=get(g:, 'timespentDateFormat', '%Y%m%d %H:%M:%S')
" using specials chars like %% is strongly unadvised

" @global g:timespentNewDayHour
" Hour that separate two days. Required by timespent#total_time_today()
" default : 6
let g:timespentNewDayHour=get(g:, 'timespentNewDayHour', 6)

" @global g:timespentTotalTimeIncludeOpenned
" Boolean to include on going time report. Required by timespent#total_time_today()
" default : 1 
let g:timespentTotalTimeIncludeOpenned=get(g:, 'timespentTotalTimeIncludeOpenned', 1)

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
let g:timespentDateRounding=get(g:, 'timespentDateRounding', 'second')

" @global g:timespentTimeRounding
" For the time spent, precise the rounding mode : second, minute, 5-minutes, 15-minutes
" default : 'second'
let g:timespentTimeRounding=get(g:, 'timespentTimeRounding', 'second')

" @global g:timespentTimeRoundingAtLeastFor_1_minute
" Precise the minimal time in seconds to declare 1 min
" default : 30
let g:timespentTimeRoundingAtLeastFor_1_minute=get(g:, 'timespentTimeRoundingAtLeastFor_1_minute', 30)

" @global g:timespentTimeRoundingAtLeastFor_5_minutes
" Precise the minimal time in seconds to declare 5 min
" default : 120
let g:timespentTimeRoundingAtLeastFor_5_minutes=get(g:, 'timespentTimeRoundingAtLeastFor_5_minutes', 120)

" @global g:timespentTimeRoundingAtLeastFor_15_minutes
" Precise the minimal time in seconds to declare 15 min
" default : 300
let g:timespentTimeRoundingAtLeastFor_15_minutes=get(g:, 'timespentTimeRoundingAtLeastFor_15_minutes', 300)

" @global g:timespentTimeTakingTime
" In seconds, time for marking time
" default : 0
let g:timespentTimeTakingTime=get(g:, 'timespentTimeTakingTime', 0)

let s:datetimeFormatRe=substitute(substitute(s:datetimeFormat, '%[HMSmdy]\C', '\\d\\d', 'g'), '%Y', '\\d\\d\\d\\d', '')
let s:timeFormatRe=substitute(s:timeFormat, '%[HMSmdy]\C', '\\d\\d', 'g')
let s:timeSeparator='|'
let s:timeSeparatorFinal=';'
let s:timeSeparatorSpaced=' '.s:timeSeparator.' '
let s:timeSeparatorFinalSpaced=' '.s:timeSeparatorFinal.' '
let s:timeSeparatorRe='\s*'.s:timeSeparator.'\s*'
let s:timeSeparatorFinalRe='\s*'.s:timeSeparatorFinal.'\s*'
let s:timeTotalSeparator='||'
let s:timeTotalSeparatorFinal='='
let s:timeTotalSeparatorSpaced=' '.s:timeTotalSeparator.' '
let s:timeTotalSeparatorRe='\s*'.s:timeTotalSeparator.'\s*'
let s:timeUnionMarker='->'
let s:timeUnionMarkerSpaced=' '.s:timeUnionMarker.' '
let s:timeUnionMarkerRe='\s*'.s:timeUnionMarker.'\s*'
let s:timeStartTo=s:datetimeFormatRe.s:timeUnionMarkerRe
let s:timeStartToEnd=s:datetimeFormatRe.s:timeUnionMarkerSpaced.s:datetimeFormatRe
let s:timeToEnd=s:timeUnionMarkerSpaced.s:datetimeFormatRe

fu! s:compute_total_time(timestamps)
  " return total time from list of ["timebegin -> timeend", ]
  let l:outputTimeFormat = get(b:, 'timespent_force_output_time_format', s:timeFormat)
python3 << EOF
import vim
import datetime
from math import trunc
 
formatstr = vim.eval("s:datetimeFormat")
rounding = vim.eval("g:timespentTimeRounding")
sep = vim.eval("s:timeUnionMarker")
min_sec_minute = int(vim.eval("g:timespentTimeRoundingAtLeastFor_1_minute"))
min_sec_5minutes = int(vim.eval("g:timespentTimeRoundingAtLeastFor_5_minutes"))
min_sec_15minutes = int(vim.eval("g:timespentTimeRoundingAtLeastFor_15_minutes"))
_unitformat = None
_hourformat = None
_minuteformat = None
_secondformat = None

def time_between(d1, d2):
    d1 = datetime.datetime.strptime(d1, formatstr)
    d2 = datetime.datetime.strptime(d2, formatstr)
    return (d2 - d1)

total = datetime.timedelta(0)
for i in list(vim.eval("a:timestamps")):
    try:
        [a, b] = i.split(sep)
        if a and b:
            total += time_between(a.strip(), b.strip())
    except Exception as e:
        continue

res = vim.eval("l:outputTimeFormat")
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
    return s:total

endfu


fu! s:update_timespent(i)
  let l:l=getline(a:i)
  if l:l =~ s:timeStartToEnd.s:timeSeparatorRe
    " cant't figure how to properly get list of elems corresponding to
    " matchlist, so just cleaning 
    let l:ts = matchlist(l:l, '\('.s:timeStartToEnd.s:timeSeparatorRe.'\)\+')[0]
    let l:ts = substitute(l:ts, s:timeSeparatorRe.'$', '', '')
    let l:ts = substitute(l:ts, s:timeSeparatorRe, s:timeSeparatorSpaced, 'g')
    let l:ts = split(l:ts, s:timeSeparatorSpaced)
    let s:total = s:compute_total_time(l:ts)
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


fu! s:get_rounded_time(datetime, end)

  let l:ret = a:datetime

  if g:timespentDateRounding == 'minute'
     if a:end 
       let l:ret += 60 - g:timespentTimeRoundingAtLeastFor_1_minute
     endif
     let l:minute_rounding = trunc(l:ret/60)*60
     if (l:minute_rounding + g:timespentTimeRoundingAtLeastFor_1_minute) <= l:ret
        let l:ret = float2nr(l:minute_rounding + 60)
     else
       let l:ret = float2nr(l:minute_rounding)
    endif
  elseif g:timespentDateRounding == '5-minutes'
     if a:end 
       let l:ret += 300 - g:timespentTimeRoundingAtLeastFor_5_minutes
     endif
     let l:minute_rounding = trunc(l:ret/300)*300
     if (l:minute_rounding + g:timespentTimeRoundingAtLeastFor_5_minutes) <= l:ret
        let l:ret = float2nr(l:minute_rounding + 300)
     else
        let l:ret = float2nr(l:minute_rounding)
    endif
  endif
  return l:ret

endfu

fu! s:get_localtime(end)
  let l:ret = localtime()
  if !a:end
     let l:ret -= g:timespentTimeTakingTime
  endif
  return s:get_rounded_time(l:ret, a:end)
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
      exe l:i.'s/'.s:timeTotalSeparator.'/'.s:timeTotalSeparatorFinal.'/'
      exe l:i.'s/'.s:timeSeparator.'/'.s:timeSeparatorFinal.'/g'
    endif
  endfor
endfu

fu! s:unfinalise_timespent(start, end)
  for l:i in range(a:start, a:end)
    let l:l=getline(l:i)
    if l:l =~ s:timeStartToEnd . s:timeSeparatorFinalRe
      exe l:i.'s/'.s:timeTotalSeparatorFinal.'/'.s:timeTotalSeparator.'/'
      exe l:i.'s/'.s:timeSeparatorFinal.'/'.s:timeSeparator.'/g'
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


fu! s:min_datetime(timelist, after)
python3 << EOF
import vim
import datetime
 
formatstr = vim.eval("s:datetimeFormat")
times = vim.eval("a:timelist")
after_date = vim.eval("a:after")
times_dict = {
    datetime.datetime.strptime(dt, formatstr) : dt
    for dt in times if dt
}
if after_date:
    after_date = datetime.datetime.strptime(after_date, formatstr)
    times_dict = {
        dt : str_dt for
        dt , str_dt in times_dict.items()
        if dt > after_date
    }
vim.command("let lDatetime = '%s'" % times_dict[min(times_dict.keys())])
EOF
  return lDatetime
endfu

fu! s:max_datetime(timelist, before)
python3 << EOF
import vim
import datetime

formatstr = vim.eval("s:datetimeFormat")
times = vim.eval("a:timelist")
before_date = vim.eval("a:before")
times_dict = {
    datetime.datetime.strptime(dt, formatstr) : dt
    for dt in times if dt
}
if before_date:
    before_date = datetime.datetime.strptime(before_date, formatstr)
    times_dict = {
        dt : str_dt for
        dt , str_dt in times_dict.items()
        if dt < before_date
    }

vim.command("let lDatetime = '%s'" % times_dict[max(times_dict.keys())])
EOF
  return lDatetime
endfu

fu! s:jump_to_datetime(pattern)
  let l:i = 0
  let l:positions = []
  while l:i < line('$')
    let l:i += 1
    let l:l = getline(l:i)
    if l:l =~ a:pattern
      call add(l:positions, [l:i, strridx(l:l, a:pattern)])
    endif
  endwhile
  let l:p = l:positions[0]
  if len(l:positions) > 1
    if l:p[0] == line('.')
      let l:p = l:positions[1]
    endif
  endif
  call setpos('.', [bufnr()] + l:p + [0])
endfu

fu! s:get_nearest_time_in_line(linenr, col)
  let l:l = getline(a:linenr)
  let l:times = []
  for l:ts in s:split_timespents(l:l, 2)
    let l:times += split(l:ts, s:timeUnionMarkerRe)
  endfor
  let l:ret = ''
  let l:nearest = len(l:l)
  for l:i in l:times
    " find closest time to the cursor by looking
    " diff with the center of the time word
    let l:diff = abs(a:col - (strridx(l:l, l:i) + (len(l:i) / 2) - 1))
    if l:diff < l:nearest
      let l:nearest = l:diff
      let l:ret = l:i
    endif
  endfor
  return l:ret
endfu
fu! s:before_timespent()
  let l:times = []
  for l:ts in s:total_time_filtered(0, 2)
    let l:times += split(l:ts, s:timeUnionMarkerRe)
  endfor
  if len(l:times)
    let l:last_time_in_line = s:get_nearest_time_in_line(line('.'), col('.'))
    call s:jump_to_datetime(s:max_datetime(l:times, l:last_time_in_line))
  endif
endfu
fu! s:after_timespent()
  let l:times = []
  for l:ts in s:total_time_filtered(0, 2)
    let l:times += split(l:ts, s:timeUnionMarkerRe)
  endfor
  if len(l:times)
    let l:last_time_in_line = s:get_nearest_time_in_line(line('.'), col('.'))
    call s:jump_to_datetime(s:max_datetime(l:times, l:last_time_in_line))
  endif
endfu

fu! s:last_timespent()
  let l:times = []
  for l:ts in s:total_time_filtered(0, 2)
    let l:times += split(l:ts, s:timeUnionMarkerRe)
  endfor
  if len(l:times)
    call s:jump_to_datetime(s:max_datetime(l:times, ''))
  endif
endfu

fu! s:next_timespent(i, step, ...)
  let l:onlyopen = get(a:000, 0, 0)
  let l:circlesearch = get(a:000, 1, 0)
  let l:imax = get(a:000, 2, 0)
  let l:imax = get(a:000, 2, 0)
  "find a line matching the pattern
  let l:i = a:i
  if line('.') == a:i
    let l:i += a:step
  endif

  let l:e=l:imax ? l:imax : line('$')

  if l:onlyopen
    while l:i > 0 && l:i <= l:e && getline(l:i) !~ s:timeStartTo.'$'
      let l:i+=a:step
    endwhile
  else
    while l:i > 0 && l:i <= l:e && getline(l:i) !~ s:timeStartTo
      let l:i+=a:step
    endwhile
  endif
  if a:step > 0
    if l:i <= l:e
      exe l:i
      return 1
    elseif l:circlesearch
        return s:next_timespent(1, a:step, l:onlyopen, 0, a:i)
    endif
  else
    if l:i >= 1
      exe l:i
      return 1
    elseif l:circlesearch
      return s:next_timespent(line('$'), a:step, l:onlyopen, 0, a:i)
    endif
  endif
  return 0
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

fu! s:update_multi_datetime_format(start, end, old_time_format)
   for l:i in range(a:start, a:end)
      call s:update_datetime_format(l:i, a:old_time_format)
  endfor
endfu

fu! s:update_datetime_format(line_number, old_time_format)
  let l:i=a:line_number
  let l:datetimeFormat = a:old_time_format
  let l:l=getline(l:i)

  let l:datetimeFormatRe=substitute(substitute(l:datetimeFormat, '%[HMSmdy]\C', '\\d\\d', 'g'), '%Y', '\\d\\d\\d\\d', '')
  let l:timeSeparator=s:timeSeparator
  let l:timeSeparatorSpaced=' '.l:timeSeparator.' '
  let l:timeSeparatorRe='\s*'.l:timeSeparator.'\s*'
  let l:timeUnionMarker=s:timeUnionMarker
  let l:timeUnionMarkerSpaced=' '.l:timeUnionMarker.' '
  let l:timeStartToEnd=l:datetimeFormatRe.l:timeUnionMarkerSpaced.l:datetimeFormatRe

  if l:l =~ l:timeStartToEnd.l:timeSeparatorRe
      let l:ts = matchlist(l:l, '\('.l:timeStartToEnd.l:timeSeparatorRe.'\)\+')[0]
      let l:ts = substitute(l:ts, l:timeSeparatorRe.'$', '', '')
      let l:ts = substitute(l:ts, l:timeSeparatorRe, l:timeSeparatorSpaced, 'g')
      let l:ts = split(l:ts, l:timeSeparatorSpaced)
      for l:ti in range(len(l:ts))
python3 << EOF
import vim
from datetime import datetime
 
formatstr = vim.eval("l:datetimeFormat")
starttime, endtime = (vim.eval('l:ts[l:ti]').split(vim.eval("l:timeUnionMarkerSpaced")) + [''])[0:2]
vim.command("let lStartTime = %s" % 
            (int(datetime.strptime(starttime, formatstr).timestamp()) if starttime else 0))
vim.command("let lEndTime = %s" %
            (int(datetime.strptime(endtime, formatstr).timestamp()) if endtime else 0))
EOF
        if lStartTime
          let l:ts[l:ti] = strftime(s:datetimeFormat, s:get_rounded_time(lStartTime, 0))
          if lEndTime
                let l:ts[l:ti] .= s:timeUnionMarkerSpaced . strftime(s:datetimeFormat, s:get_rounded_time(lEndTime, 1))
          endif
        endif
        unlet lStartTime
        unlet lEndTime
      endfor

      call setline(l:i, join(l:ts, s:timeSeparatorSpaced) . s:timeSeparatorSpaced)
      call s:update_timespent(l:i)
  endif
endfu


fu! s:split_timespents(lstr, include_openned)
    "  :param: lstr               the line
    "  :param: include_openned    0 = no; 1 = end is localtime; 2 = keep original 
    let l:l = a:lstr
    let l:ts = []
    if l:l =~ s:timeStartToEnd.s:timeSeparatorRe
      let l:ts = matchlist(l:l, '\('.s:timeStartToEnd.s:timeSeparatorRe.'\)\+')[0]
      let l:ts = substitute(l:ts, s:timeSeparatorRe.'$', '', '')
      let l:ts = substitute(l:ts, s:timeSeparatorRe, s:timeSeparatorSpaced, 'g')
      let l:ts = split(l:ts, s:timeSeparatorSpaced)
    elseif l:l =~ s:timeStartToEnd.s:timeSeparatorFinalRe
      let l:ts = matchlist(l:l, '\('.s:timeStartToEnd.s:timeSeparatorFinalRe.'\)\+')[0]
      let l:ts = substitute(l:ts, s:timeSeparatorFinalRe.'$', '', '')
      let l:ts = substitute(l:ts, s:timeSeparatorFinalRe, s:timeSeparatorSpaced, 'g')
      let l:ts = split(l:ts, s:timeSeparatorSpaced)
    endif
    if a:include_openned && l:l =~ s:timeStartTo.'$'
      if a:include_openned == 1
        let l:curtime = strftime(s:datetimeFormat, s:get_localtime(1))
      elseif a:include_openned == 2
        let l:curtime = ''
      endif
      let l:ts += [ matchlist(l:l, s:timeStartTo.'$')[0] . l:curtime ]
    endif

    return l:ts
endfu

fu! s:total_time_filtered(...)
  let l:time_spents=[]

  let TimeFilter = get(a:000, 0, 0)
  let l:include_openned = get(a:000, 1, 0)
  let SubjectFilter = get(a:000, 2, 0)
  let l:range_start = get(a:000, 3, 1)
  let l:range_end = get(a:000, 4, line('$'))

  let l:time_filter_str = ''
  let l:subject_filter_str = ''

  if type(TimeFilter) == v:t_string && len(TimeFilter)
    let l:time_filter_str = TimeFilter
    let TimeFilter = { timespents -> filter(timespents, 'v:val =~ "'.l:time_filter_str.'"') }
  endif
  let l:time_filter_exists = (type(TimeFilter) == v:t_func)


  if type(SubjectFilter) == v:t_string && len(SubjectFilter)
    let l:subject_filter_str = SubjectFilter
    let SubjectFilter = { line -> line =~ l:subject_filter_str }
  endif
  let l:subject_filter_exists = (type(SubjectFilter) == v:t_func)
  let l:skip = l:subject_filter_exists

  for l:i in range(l:range_start,l:range_end)
    let l:l=getline(l:i)
    if l:l =~ s:timeStartTo
      if l:skip
        continue
      endif
    else
      if l:subject_filter_exists
        let l:skip = SubjectFilter(l:ts)
      endif
      continue
    endif
    let l:ts = s:split_timespents(l:l, l:include_openned)
    if len(l:ts)
      if l:time_filter_exists
        let l:time_spents += TimeFilter(l:ts)
      else
        let l:time_spents += l:ts
      endif
    endif
  endfor
  return l:time_spents
endfu

" @function timespent#total_time()
" return formatted time of all timespent found in the buffer
fu! timespent#total_time()
   return s:compute_total_time(s:total_time_filtered(0))
endfu

" @function timespent#total_time_filtered([timefilter], [subjectfilter])
" return formatted time of all timespent found according a regexp filter
fu! timespent#total_time_filtered(...)
   let l:filter=0
   let l:subject_filter=0
   for l:i in a:000
     if type(l:i) == v:t_func
       if !l:filter
         let l:filter=l:i
       else
         l:subject_filter=l:i
       endif
     elseif type(l:i) == v:t_str
       if len(l:i)
         if l:i =~ '^\d\+$' || l:i =~ s:datetimeFormatRe
           let l:filter=l:i
         else
           let l:subject_filter=l:i
         endif
       endif
     endif
   endif
   return s:compute_total_time(s:total_time_filtered(l:filter, 0, l:subject_filter))
endfu

" @function timespent#total_time_today()
" return formatted time of all timespent found today
" (include time before midnight if hour < newDayHour)
fu! timespent#total_time_today()
   let l:substs = {}
   let l:substs_yesterday = {}
   let l:yesterday = 0
   let l:include_yesterday=(str2nr(strftime('%H')) < g:timespentNewDayHour)

   if l:include_yesterday
     let l:yesterday = localtime() - 86400
     let l:hours_today = range(0, g:timespentNewDayHour - 1)
     let l:hours_yesterday = range(g:timespentNewDayHour, 23)
   else
     let l:hours_today =  range(g:timespentNewDayHour, 23)
   endif

   let l:datefmttmp = s:datetimeFormat
   while len(l:datefmttmp)
     let l:str_pos = matchstrpos(l:datefmttmp, '%[a-zA-Z]')
     if l:str_pos[1] == -1
       break
     endif
     let l:time_chr=l:str_pos[0]
     let l:tref = l:time_chr[1]
     let l:datefmttmp = l:datefmttmp[l:str_pos[2]:]
     if l:tref ==# 'Y' || l:tref ==# 'y' || l:tref ==# 'm' || l:tref ==# 'd'
       let l:substs[l:time_chr] = strftime(l:time_chr)
       if l:include_yesterday
         let l:substs_yesterday[l:time_chr] = strftime(l:time_chr, l:yesterday)
       endif
     elseif l:tref ==# 'H'
       let l:substs[l:time_chr] = '\\('.join(map(l:hours_today, 'printf("%02d", v:val)'),'\\|').'\\)'
       if l:include_yesterday
         let l:substs_yesterday[l:time_chr] = '\\('.join(map(l:hours_yesterday, 'printf("%02d", v:val)'),'\\|').'\\)'
       endif
     elseif l:tref ==# 'M' || l:tref ==# 'S'
       let l:substs[l:time_chr] = '[0-9][0-9]'
       let l:substs_yesterday[l:time_chr] = l:substs[l:time_chr]
     else
       let l:substs[l:time_chr] = '\w*'
       let l:substs_yesterday[l:time_chr] = l:substs[l:time_chr]
     endif
   endwhile

   let l:possible1 = s:datetimeFormat
   for l:k in keys(l:substs)
     let l:possible1 = substitute(l:possible1, '\C'.l:k, l:substs[k], '')
   endfor
   if l:include_yesterday
     let l:possible2 = s:datetimeFormat
     for l:k in keys(l:substs_yesterday)
       let l:possible2 = substitute(l:possible2, '\C'.l:k, l:substs_yesterday[k], '')
     endfor
   endif

   if l:include_yesterday
     let TimeFilter = { timespents -> filter(timespents, "v:val =~ '".l:possible1."' || v:val =~ '".l:possible2."'")}
   else
     let TimeFilter = { timespents -> filter(timespents, "v:val =~ '".l:possible1."'")}
   endif
   let l:timespents = s:total_time_filtered(TimeFilter, g:timespentTotalTimeIncludeOpenned)
   return s:compute_total_time(l:timespents)
endfu

fu! s:total_on_days(days)
   " total time on days given from 00:00 to 23:59 (newDayHour is not used here)
   let l:substs = {}

   let l:days = []

   let l:datefmt = s:datetimeFormat
   let l:startidx = 0
   while 1
     let l:str_pos = matchstrpos(l:datefmt, '%[a-zA-Z]', l:startidx)
     if l:str_pos[1] == -1
       break
     endif
     let l:startidx = l:str_pos[2]
     let l:time_chr=l:str_pos[0]
     let l:tref = l:time_chr[1]

     if l:tref ==# 'Y' || l:tref ==# 'y' || l:tref ==# 'm' || l:tref ==# 'd'
       continue
     elseif l:tref ==# 'H' || l:tref ==# 'M' || l:tref ==# 'S'
       let l:datefmt = substitute(l:datefmt, '\C'.l:time_chr, '[0-9][0-9]', 'g')
     else
       let l:datefmt = substitute(l:datefmt, '\C'.l:time_chr, '\w*', 'g')
     endif
   endwhile

   for l:i in a:days
     call add(l:days, strftime(l:datefmt, l:i))
   endfor

   let l:possibles = '\('.join(l:days, '\|').'\)'
   let TimeFilter = { timespents -> filter(timespents, "v:val =~ '".l:possibles."'")}
   let l:timespents = s:total_time_filtered(TimeFilter, g:timespentTotalTimeIncludeOpenned)
   return s:compute_total_time(l:timespents)
endfu

" @function timespent#total_nth_day(nb_days, [end_offset=0], [week_mode=0])
" return formatted time of all timespent found from days
fu! timespent#total_nth_day(nb_days, ...)
  let l:end_offset = get(a:000, 0, 0) 
  let l:weekmode = get(a:000, 1, 0) 
  let l:days = []
  let l:day = localtime()
  let l:nb_days = a:nb_days

  if l:weekmode   " then this is weeks
    let l:week_offset = (a:nb_days) * 7
    let l:nb_days = (str2nr(strftime('%u', l:day)) - 1) + l:week_offset
    let l:day = l:day - ( l:end_offset * 7 * 86400 )
  else
    let l:day = l:day - (l:end_offset * 86400)
  endif

  for l:i in range(0, l:nb_days)
    call add(l:days, l:day - (l:i * 86400))
  endfor
  return s:total_on_days(l:days)
endfu

" @function timespent#total_previous_week()
" return formatted time of all timespent previous week
" = timespent#total_nth_day(0, 1, 1)
fu! timespent#total_previous_week()
   return timespent#total_nth_day(0, 1, 1)
endfu

" @function timespent#total_this_week()
" return formatted time of all timespent this week
" = timespent#total_nth_day(0, 0, 1)
fu! timespent#total_past_week()
   return timespent#total_nth_day(0, 0, 1)
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

