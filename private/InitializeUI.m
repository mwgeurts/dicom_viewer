function handles = InitializeUI(handles)
% InitializeUI is called by DicomViewer when the interface is opened to set
% all UI fields.
% 
% Author: Mark Geurts, mark.w.geurts@gmail.com
% Copyright (C) 2017 University of Wisconsin Board of Regents
%
% This program is free software: you can redistribute it and/or modify it 
% under the terms of the GNU General Public License as published by the  
% Free Software Foundation, either version 3 of the License, or (at your 
% option) any later version.
%
% This program is distributed in the hope that it will be useful, but 
% WITHOUT ANY WARRANTY; without even the implied warranty of 
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General 
% Public License for more details.
% 
% You should have received a copy of the GNU General Public License along 
% with this program. If not, see http://www.gnu.org/licenses/.

% Disable image viewers
set(allchild(handles.transverse), 'visible', 'off'); 
set(handles.transverse, 'visible', 'off');
set(allchild(handles.coronal), 'visible', 'off'); 
set(handles.coronal, 'visible', 'off');
set(allchild(handles.sagittal), 'visible', 'off'); 
set(handles.sagittal, 'visible', 'off');
colorbar(handles.sagittal, 'off');

% Disable sliders/alpha
set(handles.trans_slider, 'visible', 'off');
set(handles.cor_slider, 'visible', 'off');
set(handles.sag_slider, 'visible', 'off');
set(handles.alpha, 'visible', 'off');

% Disable DVH
set(allchild(handles.dvh), 'visible', 'off'); 
set(handles.dvh, 'visible', 'off');
set(handles.struct_table, 'visible', 'off');

% Set the path
handles.path = handles.config.DEFAULT_PATH;

% Set the default transparency
set(handles.alpha, 'String', sprintf('%0.0f%%', ...
    handles.config.DEFAULT_TRANSPARENCY * 100));
Event(['Default dose view transparency set to ', ...
    get(handles.alpha, 'String')]);