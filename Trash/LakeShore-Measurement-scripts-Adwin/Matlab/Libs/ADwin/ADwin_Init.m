%ADwin_Init  initializes Matlab for communication with ADwin systems.
%
%  Syntax:  ADwin_Init()
%
%  Notes:
%    During initialization important default values are set among them the
%    following:
%    - DeviceNo = 1; see also Set_DeviceNo (below).
%    - Show_Errors = On; see also Show_Errors (page 37).
%    ADwin_Init must be called first, in order to make ADwin functions run
%    correctly. If the call misses and an ADwin function is being used, the
%    function will call ADwin_Init by itself.
%
%  Example:
%    % Initialize Matlab for communication with ADwin,
%    % set default device number 1 and show errors.
%    ADwin_Init();
%
%  See also  ADWIN_UNLOAD, SHOW_ERRORS, SET_DEVICENO, GET_DEVICENO.
%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2016 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.00 $  $Date: 2016-02-01  09:30:19 $
