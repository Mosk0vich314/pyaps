%Get_Last_Error_Text  returns the error text to a given error number.
%
%  Syntax:  Get_Last_Error_Text (Last_Error)
%
%  Parameters:
%    Last_Error      Error number
%    Return value    Error text
%
%  Notes:
%    Usually, the return value of the function Get_Last_Error is used as error
%    number Last_Error.
%
%  Example:
%    errnum = Get_Last_Error();
%    if errnum!=0
%     pErrText = Get_Last_Error_Text(errnum);
%    end
%
%  See also  GET_LAST_ERROR, TEST_VERSION
%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2016 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.00 $  $Date: 2016-02-01  09:30:19 $
