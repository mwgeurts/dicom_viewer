function varargout = DicomViewer(varargin)
% DicomViewer loads and displays the contents of DICOM RT files. 
% The interface allows the user to select a folder to scan for DICOM files, 
% then loads the file contents into a series of simple MATLAB objects and 
% displays the CT transverse, coronal, and sagittal axes with overlaying 
% contours and dose colorwash. An RT structure Set and RT Dose file is 
% optional, but if provided, a DVH will also be displayed along with a 
% table for adjusting contour display and reporting the dose values for a 
% given relative volume.
%
% Author: Mark Geurts, mark.w.geurts@gmail.com
% Copyright (C) 2018 University of Wisconsin Board of Regents
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

% Last Modified by GUIDE v2.5 04-Jan-2018 09:27:58

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DicomViewer_OpeningFcn, ...
                   'gui_OutputFcn',  @DicomViewer_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DicomViewer_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to DicomViewer (see VARARGIN)

% Turn off MATLAB warnings
warning('off','all');

% Choose default command line output for DicomViewer
handles.output = hObject;

% Set version handle
handles.version = '1.3.0';

% Determine path of current application
[path, ~, ~] = fileparts(mfilename('fullpath'));

% Set current directory to location of this application
cd(path);

% Clear temporary variable
clear path;

% Set version information.  See LoadVersionInfo for more details.
handles.versionInfo = LoadVersionInfo;

% Store program and MATLAB/etc version information as a string cell array
string = {'Simple DICOM RT Viewer'
    sprintf('Version: %s (%s)', handles.version, handles.versionInfo{6});
    sprintf('Author: Mark Geurts <mark.w.geurts@gmail.com>');
    sprintf('MATLAB Version: %s', handles.versionInfo{2});
    sprintf('MATLAB License Number: %s', handles.versionInfo{3});
    sprintf('Operating System: %s', handles.versionInfo{1});
    sprintf('CUDA: %s', handles.versionInfo{4});
    sprintf('Java Version: %s', handles.versionInfo{5})
};

% Add dashed line separators      
separator = repmat('-', 1,  size(char(string), 2));
string = sprintf('%s\n', separator, string{:}, separator);

% Log information
Event(string, 'INIT');

% Load config file
handles.config = ParseConfigOptions('config.txt');

% Add submodules
AddSubmodulePaths(handles.config);

% Initialize UI
handles = InitializeUI(handles);

% Report initilization status
Event(['Initialization completed successfully. Start by loading a ', ...
    'DICOM directory containing images, a structure set, and a dose.']);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = DicomViewer_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function trans_slider_Callback(hObject, ~, handles) %#ok<*DEFNU>
% hObject    handle to trans_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Update viewer with current slice
handles.tplot.Update('slice', round(get(hObject, 'Value')));

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function trans_slider_CreateFcn(hObject, ~, ~)
% hObject    handle to trans_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Set light gray background
if isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cor_slider_Callback(hObject, ~, handles)
% hObject    handle to cor_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Update viewer with current slice
handles.cplot.Update('slice', round(get(hObject, 'Value')));

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cor_slider_CreateFcn(hObject, ~, ~)
% hObject    handle to cor_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Set light gray background
if isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sag_slider_Callback(hObject, ~, handles)
% hObject    handle to sag_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Update viewer with current slice
handles.splot.Update('slice', round(get(hObject, 'Value')));

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sag_slider_CreateFcn(hObject, ~, ~)
% hObject    handle to sag_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Set light gray background
if isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function struct_table_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to dvh_table (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty 
%       if Data was not changed
%	Error: error string when failed to convert EditData to appropriate 
%       value for Data
% handles    structure with handles and user data (see GUIDATA)

% Get current data
data = get(hObject, 'Data');

% Verify edited Dx value is a number or empty
if eventdata.Indices(2) == 3 && isnan(str2double(...
        data{eventdata.Indices(1), eventdata.Indices(2)})) && ...
        ~isempty(data{eventdata.Indices(1), eventdata.Indices(2)})
    
    % Warn user
    Event(sprintf('Dx value "%s" is not a number', ...
        data{eventdata.Indices(1), eventdata.Indices(2)}), 'WARN');
    
    % Revert value to previous
    data{eventdata.Indices(1), eventdata.Indices(2)} = ...
        eventdata.PreviousData;
    set(hObject, 'Data', data);

% Otherwise, if Dx was changed
elseif eventdata.Indices(2) == 3
    
    % Update edited Dx/Vx statistic
    handles.dplot.UpdateTable('data', data, 'row', eventdata.Indices(1));

% Otherwise, if display value was changed
elseif eventdata.Indices(2) == 2
    
    % Update TCS plots
    handles.tplot.Update('structuresonoff', data);
    handles.cplot.Update('structuresonoff', data);
    handles.splot.Update('structuresonoff', data);
    
    % Update edited Dx/Vx statistic
    handles.dplot.UpdatePlot('data', data);
end

% Clear temporary variable
clear data;

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function alpha_Callback(hObject, ~, handles)
% hObject    handle to alpha (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% If the string contains a '%', parse the value
if contains(get(hObject, 'String'), '%')
    value = sscanf(get(hObject, 'String'), '%f%%');
    
% Otherwise, attempt to parse the response as a number
else
    value = str2double(get(hObject, 'String'));
end

% Bound value to [0 100]
value = max(0, min(100, value));

% Update viewers with transparency value
handles.tplot.Update('alpha', value/100);
handles.cplot.Update('alpha', value/100);
handles.splot.Update('alpha', value/100);

% Clear temporary variable
clear value;

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function alpha_CreateFcn(hObject, ~, ~)
% hObject    handle to alpha (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Set white background
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function input_folder_Callback(~, ~, ~)
% hObject    handle to input_folder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function input_folder_CreateFcn(hObject, ~, ~)
% hObject    handle to input_folder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Set white background
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function browse_button_Callback(hObject, ~, handles)
% hObject    handle to browse_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log event
Event('Folder browse button selected');

% Execute BrowseDICOMimages
handles = BrowseDICOMimages(handles);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DebugWriteDICOM(handles, path)
% This function is used for debugging and validation purposes, and writes
% the stored DICOM data back out using the WriteDICOM* functions in the
% dicom_tools submodule. The function is executed using the DicomViewer
% handles structure and a destination path to write to.

% Write DICOM images (force new SOPs and frameRefUID)
handles.image = rmfield(handles.image, 'instanceUIDs');
handles.image.frameRefUID = dicomuid;
handles.image.instanceUIDs = ...
    WriteDICOMImage(handles.image, fullfile(path, 'IMG'), handles.image);

% Write DICOM structures
if isfield(handles.image, 'structures')
    WriteDICOMStructures(handles.image.structures, ...
        fullfile(path, 'RTSS.dcm'), handles.image);
end

% Write DICOM dose
if isfield(handles, 'dose')
    WriteDICOMDose(handles.dose, fullfile(path, 'RTDOSE.dcm'), ...
        handles.image);
end

% Write DVH
WriteDVH(handles.image, handles.dose, fullfile(path, 'DVH.csv'));
