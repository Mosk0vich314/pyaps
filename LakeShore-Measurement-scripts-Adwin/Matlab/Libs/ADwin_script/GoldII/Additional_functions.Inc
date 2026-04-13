'<ADbasic Header, Headerversion 001.001>
'<Header End>
function get_bit(bit, value) as long
  dim a as long
  a=1
  if(((shift_left(a,bit)) and value) =0) then
    get_bit=0
  else
    get_bit=1
  endif
endfunction

