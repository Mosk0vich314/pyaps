%Fifo_Empty  returns the number of empty elements in a FIFO array.
%
%  Syntax:  Fifo_Empty (FifoNo)
%
%  Parameters:
%    FifoNo          Number (1...200) of the FIFO array DATA_1 ... DATA_200.
%    Return value    <>255: Number of empty elements in the FIFO array.
%                    255: Error
%
%  Example:
%    %In ADbasic DATA_5 is dimensioned as:
%    DIM DATA_5[100] AS LONG AS FIFO
%    
%    %In MATLAB you will get the number of empty elements in DATA_5:
%    >> Fifo_Empty(5)
%    ans =
%        68
%
%  See also  GETDATA_DOUBLE, SETDATA_DOUBLE, GETFIFO_DOUBLE, SETFIFO_DOUBLE, FIFO_FULL, FIFO_CLEAR, DATA2FILE.
%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2016 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.00 $  $Date: 2016-02-01  09:30:19 $
