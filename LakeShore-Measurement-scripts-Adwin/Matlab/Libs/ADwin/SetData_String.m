%SetData_String  transfers a string into DATA array.
%
%  Syntax:  SetData_String (DataNo, String)
%
%  Parameters:
%    DataNo          Number (1...200) of the FIFO array DATA_1 ... DATA_200.
%    String          String variable or text in quotes which is to be
%                    transferred.
%    Return value    <>-1: OK
%                    -1: Error
%
%  Notes:
%    This function cannot be used in connection with ADsim.
%    SetData_String appends the termination char (ASCII character 0) to each
%    transferred string.
%
%  Example:
%    SetData_String(2,'Hello World');
%    %The string "Hello World" is written into the array DATA_2 and the
%    %termination char is added.
%
%  See also  STRING_LENGTH, GETDATA_STRING, GETDATA_DOUBLE, SETDATA_DOUBLE, GETFIFO_DOUBLE, SETFIFO_DOUBLE, FIFO_FULL, FIFO_EMPTY, FIFO_CLEAR, DATA2FILE.
%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2016 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.00 $  $Date: 2016-02-01  09:30:19 $
