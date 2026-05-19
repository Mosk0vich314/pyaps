%Get_Par  returns the value of a global variable PAR.
%
%  Syntax:  Get_Par (Index)
%
%  Parameters:
%    Index           Number (1 ... 80) of the global variable PAR_1 ... PAR_80.
%    return value    <>255: Current value of the variable
%                    255: Error
%
%  Example:
%    % Read value of the LONG variable PAR_1
%    x = Get_Par(1);
%
%  See also  GET_FPAR, GET_PAR_ALL, GET_PAR_BLOCK, GET_FPAR_ALL, GET_FPAR_BLOCK, SET_PAR, SET_FPAR.
%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2016 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.00 $  $Date: 2016-02-01  09:30:19 $
