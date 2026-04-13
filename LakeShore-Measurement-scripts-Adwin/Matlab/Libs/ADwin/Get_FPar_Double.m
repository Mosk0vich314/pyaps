%Get_FPar_Double  returns the double value of a global variable FPAR.
%
%  Syntax:  Get_FPar_Double_Double (Index)
%
%  Parameters:
%    Index           Number (1 ... 80) of the global variable FPAR_1 ...
%                    FPAR_80.
%    Return value    <>255: Current double value of the variable
%                    255: Error
%
%  Notes:
%    Until T11, please note: float values in the ADwin system have 32 bit
%    precision. Nevertheless, Get_FPar_Double will return a value of data type
%    double.
%
%  Example:
%    % Read the value of the variable FPAR_56
%    ret_val = Get_FPar_Double(56);
%
%  See also  GET_FPAR_ALL_DOUBLE, GET_FPAR_BLOCK_DOUBLE, SET_FPAR_DOUBLE, GET_FPAR.
%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2016 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.00 $  $Date: 2016-02-01  09:30:19 $
