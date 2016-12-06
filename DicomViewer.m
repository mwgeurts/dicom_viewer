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
% Copyright (C) 2016 University of Wisconsin Board of Regents
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

% Last Modified by GUIDE v2.5 09-Nov-2016 20:21:53

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
handles.version = '1.1.0';

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

%% Add submodule
% Add archive extraction tools submodule to search path (../dicom_tools
% added for debugging)
addpath('./dicom_tools');
% addpath('../dicom_tools');

% Check if MATLAB can find LoadDICOMImages
if exist('LoadDICOMImages', 'file') ~= 2
    
    % If not, throw an error
    Event(['The DICOM Tools submodule does not exist in the ', ...
        'search path. Use git clone --recursive or git submodule init ', ...
        'followed by git submodule update to fetch all submodules'], ...
        'ERROR');
end

% Check if MATLAB can find dicominfo
if exist('dicominfo', 'file') ~= 2
    
    % If not, throw an error
    Event(['The MATLAB Image Processing toolbox must be installed to run ', ...
        'this application'], 'ERROR');
end

%% Initialize UI
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

%% Initialize global variables
% Default folder path when selecting input files
handles.userpath = userpath;
Event(['Default file path set to ', handles.userpath]);

% Set the default transparency
set(handles.alpha, 'String', '40%');
Event(['Default dose view transparency set to ', ...
    get(handles.alpha, 'String')]);

%% Complete initialization
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

% Round the current value to an integer value
set(hObject, 'Value', round(get(hObject, 'Value')));

% Log event
Event(sprintf('Transverse viewer slice set to %i', get(hObject,'Value')));

% Update viewer with current slice and transparency value
UpdateViewer(get(hObject,'Value'), sscanf(get(handles.alpha, 'String'), ...
    '%f%%')/100, get(handles.struct_table, 'data'), handles.transverse, 'T', ...
    handles.image, handles.idose);

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

% Round the current value to an integer value
set(hObject, 'Value', round(get(hObject, 'Value')));

% Log event
Event(sprintf('Coronal viewer slice set to %i', get(hObject,'Value')));

% Update viewer with current slice and transparency value
UpdateViewer(get(hObject,'Value'), sscanf(get(handles.alpha, 'String'), ...
    '%f%%')/100, get(handles.struct_table, 'data'), handles.coronal, 'C', ...
    handles.image, handles.idose);

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

% Round the current value to an integer value
set(hObject, 'Value', round(get(hObject, 'Value')));

% Log event
Event(sprintf('Sagittal viewer slice set to %i', get(hObject,'Value')));

% Update viewer with current slice and transparency value
UpdateViewer(get(hObject,'Value'), sscanf(get(handles.alpha, 'String'), ...
    '%f%%')/100, get(handles.struct_table, 'data'), handles.sagittal, 'S', ...
    handles.image, handles.idose);

% If dose is present
if isfield(handles, 'dose')

    % Enable colorbar
    colorbar(handles.sagittal);
end

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
stats = get(hObject, 'Data');

% Verify edited Dx value is a number or empty
if eventdata.Indices(2) == 3 && isnan(str2double(...
        stats{eventdata.Indices(1), eventdata.Indices(2)})) && ...
        ~isempty(stats{eventdata.Indices(1), eventdata.Indices(2)})
    
    % Warn user
    Event(sprintf(['Dx value "%s" is not a number, reverting to previous ', ...
        'value'], stats{eventdata.Indices(1), eventdata.Indices(2)}), 'WARN');
    
    % Revert value to previous
    stats{eventdata.Indices(1), eventdata.Indices(2)} = ...
        eventdata.PreviousData;
    
% Otherwise, if Dx was changed
elseif eventdata.Indices(2) == 3
    
    % Update edited Dx/Vx statistic
    stats = UpdateDoseStatistics(stats, eventdata.Indices);
    
% Otherwise, if display value was changed
elseif eventdata.Indices(2) == 2

    % Update viewers plot if displayed
    if strcmp(get(handles.trans_slider, 'visible'), 'on')

        % Update viewer with current slice and transparency value
        UpdateViewer(get(handles.trans_slider, 'Value'), ...
            sscanf(get(handles.alpha, 'String'), ...
            '%f%%')/100, stats, handles.transverse, 'T', handles.image, ...
            handles.idose);

        % Update viewer with current slice and transparency value
        UpdateViewer(get(handles.cor_slider, 'Value'), ...
            sscanf(get(handles.alpha, 'String'), ...
            '%f%%')/100, stats, handles.coronal, 'C', handles.image, ...
            handles.idose);

        % Update viewer with current slice and transparency value
        UpdateViewer(get(handles.sag_slider, 'Value'), ...
            sscanf(get(handles.alpha, 'String'), ...
            '%f%%')/100, stats, handles.sagittal, 'S', handles.image, ...
            handles.idose);
        
        % If dose is present
        if isfield(handles, 'dose')
            
            % Enable colorbar
            colorbar(handles.sagittal);
        end
    end

    % Update DVH plot if it is displayed
    if strcmp(get(handles.dvh, 'visible'), 'on')
        
        % Update DVH plot
        UpdateDVH(stats); 
    end
end

% Set new table data
set(hObject, 'Data', stats);

% Clear temporary variable
clear stats;

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function alpha_Callback(hObject, ~, handles)
% hObject    handle to alpha (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% If the string contains a '%', parse the value
if ~isempty(strfind(get(hObject, 'String'), '%'))
    value = sscanf(get(hObject, 'String'), '%f%%');
    
% Otherwise, attempt to parse the response as a number
else
    value = str2double(get(hObject, 'String'));
end

% Bound value to [0 100]
value = max(0, min(100, value));

% Log event
Event(sprintf('Dose transparency set to %0.0f%%', value));

% Update string with formatted value
set(hObject, 'String', sprintf('%0.0f%%', value));

% Update viewer with current slice and transparency value
UpdateViewer(get(handles.trans_slider, 'Value'), value/100, ...
    get(handles.struct_table, 'data'), handles.transverse, 'T', ...
    handles.image, handles.idose);

% Update viewer with current slice and transparency value
UpdateViewer(get(handles.cor_slider, 'Value'), value/100, ...
    get(handles.struct_table, 'data'), handles.coronal, 'C', ...
    handles.image, handles.idose);

% Update viewer with current slice and transparency value
UpdateViewer(get(handles.sag_slider, 'Value'), value/100, ...
    get(handles.struct_table, 'data'), handles.sagittal, 'S', ...
    handles.image, handles.idose);

% If dose is present
if isfield(handles, 'dose')

    % Enable colorbar
    colorbar(handles.sagittal);
end
        
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

% Request the user to select a folder
Event('UI window opened to select input folder');
handles.path = uigetdir(handles.userpath, 'Select the Folder to Open');

% If the user selected a file
if ~isequal(handles.path, 0)

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
    
    % Clear existing data
    if isfield(handles, 'image')
        handles = rmfield(handles, 'image');
    end
    
    % Dose exists
    if isfield(handles, 'dose')
        handles = rmfield(handles, 'dose');
        handles = rmfield(handles, 'idose');
    end
    
    % Set path
    set(handles.input_folder, 'String', handles.path);
    
    % Start waitbar
    progress = waitbar(0, 'Scanning path for DICOM files');
    
    % Scan the directory for DICOM files
    Event(['Scanning ', handles.path, ' for DICOM files']);
    
    % Retrieve folder contents of selected directory
    list = dir(handles.path);
    
    % Initialize folder counter
    i = 0;
    
    % Initialize list of DICOM files
    imagefiles = cell(0);
    rtssfiles = cell(0);
    dosefiles = cell(0);

    % Start recursive loop through each folder, subfolder
    while i < length(list)
    
        % Increment current folder being analyzed
        i = i + 1;
        
        % Update waitbar
        waitbar(i/length(list), progress);

        % If the folder content is . or .., skip to next folder in list
        if strcmp(list(i).name, '.') || strcmp(list(i).name, '..')
            continue
        
        % Otherwise, if the folder content is a subfolder    
        elseif list(i).isdir == 1

            % Retrieve the subfolder contents
            sublist = dir(fullfile(handles.path, list(i).name));

            % Look through the subfolder contents
            for j = 1:size(sublist, 1)

                % If the subfolder content is . or .., skip to next subfolder 
                if strcmp(sublist(j).name, '.') || ...
                        strcmp(sublist(j).name, '..')
                    continue
                else

                    % Otherwise, replace the subfolder name with its full
                    % reference
                    sublist(j).name = fullfile(list(i).name, ...
                        sublist(j).name);
                end
            end

            % Append the subfolder contents to the main folder list
            list = vertcat(list, sublist); %#ok<AGROW>

            % Clear temporary variable
            clear sublist;

        % Otherwise, see if the file is a DICOM file
        else
        
            % Attempt to parse the DICOM header
            try
                % Execute dicominfo
                info = dicominfo(fullfile(handles.path, list(i).name));
                
                % Verify storage class field exists
                if ~isfield(info, 'MediaStorageSOPClassUID')
                    continue
                end
                
                % If CT or MR, add to imagefiles
                if strcmp(info.MediaStorageSOPClassUID, ...
                        '1.2.840.10008.5.1.4.1.1.2') || ...
                        strcmp(info.MediaStorageSOPClassUID, ...
                        '1.2.840.10008.5.1.4.1.1.4')
                    imagefiles{length(imagefiles)+1} = list(i).name;
                    
                % Otherwise, if structure, add to rtssfiles
                elseif strcmp(info.MediaStorageSOPClassUID, ...
                        '1.2.840.10008.5.1.4.1.1.481.3')
                    rtssfiles{length(rtssfiles)+1} = list(i).name;
                    
                % Otherwise, if dose, add to dosefiles
                elseif strcmp(info.MediaStorageSOPClassUID, ...
                        '1.2.840.10008.5.1.4.1.1.481.2')
                    dosefiles{length(dosefiles)+1} = list(i).name;
                end
                
            % If an exception occurs, the file is not a DICOM file so skip
            catch
                continue
            end
        end
    end
    
    % Close waitbar
    close(progress);
    
    % Log completion
    Event(sprintf(['Scan completed, finding %i image, %i structure ', ...
        'sets, and %i dose files'], length(imagefiles), length(rtssfiles), ...
        length(dosefiles)));
    
    % Only continue if at least one image was found
    if ~isempty(imagefiles)
        
        % Load the DICOM CT
        handles.image = LoadDICOMImages(handles.path, imagefiles);
    
        % If a structure set was found
        if ~isempty(rtssfiles)
            
            % Load the first RTSS
            handles.image.structures = LoadDICOMStructures(handles.path, ...
                rtssfiles{1}, handles.image);
        end
        
        % If a dose was found
        if ~isempty(dosefiles)
            
            % Load the first RTDOSE
            handles.dose = LoadDICOMDose(handles.path, dosefiles{1});
            handles.dose.registration = [0 0 0 0 0 0];
            
            % If the dose array is not identical to the image, re-sample it
            if ~isequal(handles.image.dimensions, handles.dose.dimensions) || ...
                    ~isequal(handles.image.width, handles.dose.width) || ...
                    ~isequal(handles.image.start, handles.dose.start)
                
                % Log action
                Event(['The dose grid is not aligned to the image and ', ...
                    'will be interpolated']);
                
                % Compute X, Y, and Z meshgrids for the CT image dataset 
                % positions using the start and width values, permuting X/Y
                [refX, refY, refZ] = meshgrid(single(handles.image.start(2) + ...
                    handles.image.width(2) * (size(handles.image.data,2) - 1): ...
                    -handles.image.width(2):handles.image.start(2)), ...
                    single(handles.image.start(1):handles.image.width(1)...
                    :handles.image.start(1) + handles.image.width(1)...
                    * (size(handles.image.data,1) - 1)), ...
                    single(handles.image.start(3):handles.image.width(3):...
                    handles.image.start(3) + handles.image.width(3)...
                    * (size(handles.image.data,3) - 1)));
                
                % Compute X, Y, and Z meshgrids for the dose dataset using
                % the start and width values, permuting X/Y
                [tarX, tarY, tarZ] = meshgrid(single(handles.dose.start(2) + ...
                    handles.dose.width(2) * (size(handles.dose.data,2) - 1): ...
                    -handles.dose.width(2):handles.dose.start(2)), ...
                    single(handles.dose.start(1):handles.dose.width(1):...
                    handles.dose.start(1) + handles.dose.width(1) ...
                    * (size(handles.dose.data,1) - 1)), ...
                    single(handles.dose.start(3):handles.dose.width(3):...
                    handles.dose.start(3) + handles.dose.width(3) ...
                    * (size(handles.dose.data,3) - 1)));
                
                % Start try-catch block to safely test for CUDA functionality
                try
                    % Clear and initialize GPU memory.  If CUDA is not enabled, or if the
                    % Parallel Computing Toolbox is not installed, this will error, and the
                    % function will automatically rever to CPU computation via the catch
                    % statement
                    gpuDevice(1);
                    
                    % Run GPU interp3 function to compute the dose
                    % values at the specified target coordinate points
                    handles.idose.data = gather(interp3(gpuArray(tarX), ...
                        gpuArray(tarY), gpuArray(tarZ), ...
                        gpuArray(single(handles.dose.data)), gpuArray(refX), ...
                        gpuArray(refY), gpuArray(refZ), 'linear', 0));
                
                % If GPU fails, revert to CPU computation
                catch

                    % Log GPU failure (if cpu flag is not set)
                    Event('GPU failed, reverting to CPU method', 'WARN'); 
                        
                    % Run CPU interp3 function to compute the dose
                    % values at the specified target coordinate points
                    handles.idose.data = interp3(tarX, tarY, tarZ, ...
                        single(handles.dose.data), refX, ...
                        refY, refZ, '*linear', 0);
                end
                
                % Set interpolated voxel parameters to CT
                handles.idose.start = handles.image.start;
                handles.idose.width = handles.image.width;
                handles.idose.dimensions = handles.image.dimensions;
            
            else
                % Otherwise, set interpolated dose to dose
                handles.idose = handles.dose;
            end
            
            % Retrieve transparency value
            alpha = sscanf(get(handles.alpha, 'String'), '%f%%')/100;
            
            % Enable transparency
            set(handles.alpha, 'enable', 'on');
            
        % Otherwise, no dose is present
        else
            
            % Create empty secondary image volume
            handles.idose.data = zeros(handles.image.dimensions);
            handles.idose.start = handles.image.start;
            handles.idose.width = handles.image.width;
            handles.idose.dimensions = handles.image.dimensions;
            alpha = 0;
            
            % Enable transparency
            set(handles.alpha, 'enable', 'off');
        end

        % Initialize transverse viewer
        InitializeViewer(handles.transverse, 'T', alpha, handles.image, ...
            handles.idose, handles.trans_slider);
        set(handles.trans_slider, 'visible', 'on');

        % Initialize coronal viewer
        InitializeViewer(handles.coronal, 'C', alpha, handles.image, ...
            handles.idose, handles.cor_slider);
        set(handles.cor_slider, 'visible', 'on');

        % Initialize sagittal viewer
        InitializeViewer(handles.sagittal, 'S', alpha, handles.image, ...
            handles.idose, handles.sag_slider);
        set(handles.sag_slider, 'visible', 'on');
        
        % If dose is present
        if isfield(handles, 'dose')
            
            % Enable colorbar
            colorbar(handles.sagittal);
        end
        
        % Make transparency viewable
        set(handles.alpha, 'visible', 'on');
        
        % If struct_table exist
        if isfield(handles.image, 'structures') && ...
                ~isempty(handles.image.structures)

            % Initialize statistics table
            stats = InitializeStatistics(handles.image);
            
            % Compute DVH
            dvh = UpdateDVH(handles.dvh, stats, handles.image, handles.idose);
            
            % Update table
            stats = UpdateDoseStatistics(stats, [], dvh);
            set(handles.struct_table, 'data', stats(:,1:4));
            set(handles.struct_table, 'visible', 'on');
        end
    end
        
    % Update default path
    handles.userpath = handles.path;
    Event(['Updating default path to ', handles.path]);
    
% Otherwise the user did not select a file
else
    Event('No folder was selected');
end

% Update handles structure
guidata(hObject, handles);

% Clear temporary variables
clear info list imagefiles rtssfiles dosefiles alpha stats dvh progress;

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

% Clear temporary files