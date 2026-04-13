%String_Length  returns the length of a data string in a DATA array.
%
%  Syntax:  String_Length (DataNo)
%
%  Parameters:
%    DataNo          Number (1...200) of the array DATA_1 ... DATA_200.
%    Return value    <>-1: String length = number of characters
%                    -1: Error
%
%  Notes:
%    This function cannot be used in connection with ADsim.
%    String_Length counts the characters in a DATA array up to the termination
%    char (ASCII character 0). The termination char is not counted as character.
%
%  Example:
%    %In ADbasic DATA_2 is dimensioned as:
%    DIM DATA_2[2000] AS STRING
%    DATA_2 = "Hello World"
%    
%    %In MATLAB you will get the length of the array DATA_2:
%    >> String_Length(2)
%    ans =
%        11
%
%  See also  GETDATA_STRING, SETDATA_STRING.
%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2016 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.00 $  $Date: 2016-02-01  09:30:19 $
