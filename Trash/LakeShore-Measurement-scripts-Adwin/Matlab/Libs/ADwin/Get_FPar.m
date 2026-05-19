%Get_FPar  returns the single value of a global variable FPAR.
%
%  Syntax:  Get_FPar (Index)
%
%  Parameters:
%    Index           Number (1 ... 80) of the global variable FPAR_1 ...
%                    FPAR_80.
%    Return value    <>255: Current single value of the variable
%                    255: Error
%
%  Notes:
%    Since processor T12, FPAR variables in the ADwin system have 64 bit
%    precision. Nevertheless, Get_FPar will return a value of data type single.
%
%  Example:
%    % Read the value of the variable FPAR_56
%    ret_val = Get_FPar(56);
%
%  See also  GET_PAR, GET_PAR_ALL, GET_PAR_BLOCK, GET_FPAR_ALL, GET_FPAR_BLOCK, SET_PAR, SET_FPAR, GET_FPAR_DOUBLE.
%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2016 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.00 $  $Date: 2016-02-01  09:30:19 $
