%Get_FPar_Block  transfers a specified number of consecutive global variables
%  FPAR into a row vector (data type single).
%
%  Syntax:  Get_FPar_Block (StartIndex, Count)
%
%  Parameters:
%    StartIndex      Number (1 ... 80) of the first global variable FPAR_1...
%                    FPAR_80 to be transferred.
%    Count           Number (>=1) of variables to be transferred.
%    Return value    Row vector with transferred values of data type single.
%
%  Example:
%    %Read values of variables PAR_10 ... PAR_34 and store in a row vector v:
%    v = Get_FPar_Block(10,25);
%
%  See also  GET_PAR, GET_FPAR, GET_PAR_ALL, GET_FPAR_ALL, GET_PAR_BLOCK, SET_PAR, SET_FPAR.
%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2016 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.00 $  $Date: 2016-02-01  09:30:19 $
