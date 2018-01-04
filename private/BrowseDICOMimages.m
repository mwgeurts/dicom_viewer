function handles = BrowseDICOMimages(handles)
% BrowseDICOMimages is called by DicomViewer when the user clicks the
% browse button. This function opens a folder browser to allow the user to 
% select an input directory, then searches for contained DICOM data and
% loads it.
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

% Clear existing plots
if isfield(handles, 'tplot')
    delete(handles.tplot);
    delete(handles.cplot);
    delete(handles.splot);
    set(handles.alpha, 'visible', 'off');
end

if isfield(handles, 'dplot')
    delete(handles.dplot);
    set(handles.struct_table, 'visible', 'off');
end

% Clear existing data
if isfield(handles, 'image')
    handles = rmfield(handles, 'image');
end

% If dose exists
if isfield(handles, 'dose')
    handles = rmfield(handles, 'dose');
end

% Clear path
set(handles.input_folder, 'String', '');

% If not executing in unit test
if ~isfield(handles.config, 'UNIT_FLAG') || ...
        str2double(handles.config.UNIT_FLAG) == 0

    % Request the user to select a folder
    Event('UI window opened to select input folder');
    path = uigetdir(handles.path, 'Select the Folder to Open');
else
    
    % Log unit test
    Event('Retrieving stored unit test path', 'UNIT');
    path = handles.config.UNIT_PATH;
end
    
% If the user selected a folder
if isequal(path, 0)
    Event('No folder was selected');
    return;
end

% Set path
set(handles.input_folder, 'String', path);

% Update default path
handles.path = path;
Event(['Updating default path to ', path]);

% Execute ScanDICOMpath to search for files
[imagefiles, rtssfiles, dosefiles] = ScanDICOMpath(path);

% Only continue if at least one image was found
if ~isempty(imagefiles)

    % Load the DICOM CT
    handles.image = LoadDICOMImages(path, imagefiles);

    % If a structure set was found
    if ~isempty(rtssfiles)

        % Load the first RTSS
        handles.image.structures = LoadDICOMStructures(path, ...
            rtssfiles{1}, handles.image, [], ...
            handles.config.IGNORE_RTSS_FOR);
    else
        handles.image.structures = struct;
    end

    % If a dose was found
    if ~isempty(dosefiles)

        % If dose file is a .3ddose
        if ~isempty(regexpi(dosefiles{1}, '\.3ddose$'))
        
            % Load the dose through Load3ddose
            handles.dose = Load3ddose(path, dosefiles{1});
        
        else
            
            % Load the first RTDOSE
            handles.dose = LoadDICOMDose(path, dosefiles{1});
        end
        
        % Set empty image registration
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
                handles.dose.data = gather(interp3(gpuArray(tarX), ...
                    gpuArray(tarY), gpuArray(tarZ), ...
                    gpuArray(single(handles.dose.data)), gpuArray(refX), ...
                    gpuArray(refY), gpuArray(refZ), 'linear', 0));

            % If GPU fails, revert to CPU computation
            catch

                % Log GPU failure (if cpu flag is not set)
                Event('GPU failed, reverting to CPU method', 'WARN'); 

                % Run CPU interp3 function to compute the dose
                % values at the specified target coordinate points
                handles.dose.data = interp3(tarX, tarY, tarZ, ...
                    single(handles.dose.data), refX, ...
                    refY, refZ, '*linear', 0);
            end

            % Set interpolated voxel parameters to CT
            handles.dose.start = handles.image.start;
            handles.dose.width = handles.image.width;
            handles.dose.dimensions = handles.image.dimensions;

        end

        % Initialize transverse viewer
        handles.tplot = ImageViewer('axis', handles.transverse, ...
            'tcsview', 'T', 'background', handles.image, ...
            'overlay', handles.dose, 'alpha', ...
            sscanf(get(handles.alpha, 'String'), '%f%%')/100, ...
            'structures', handles.image.structures, ...
            'slider', handles.trans_slider, 'cbar', 'off', 'pixelval', 'on');

        % Initialize coronal viewer
        handles.cplot = ImageViewer('axis', handles.coronal, ...
            'tcsview', 'C', 'background', handles.image, ...
            'overlay', handles.dose, 'alpha', ...
            sscanf(get(handles.alpha, 'String'), '%f%%')/100, ...
            'structures', handles.image.structures, ...
            'slider', handles.cor_slider, 'cbar', 'off', 'pixelval', 'on');

        % Initialize sagittal viewer
        handles.splot = ImageViewer('axis', handles.sagittal, ...
            'tcsview', 'S', 'background', handles.image, ...
            'overlay', handles.dose, 'alpha', ...
            sscanf(get(handles.alpha, 'String'), '%f%%')/100, ...
            'structures', handles.image.structures, ...
            'slider', handles.sag_slider, 'cbar', 'on', 'pixelval', 'on');

        % Enable transparency
        set(handles.alpha, 'visible', 'on');

    % Otherwise, no dose is present
    else

        % Initialize transverse viewer
        handles.tplot = ImageViewer('axis', handles.transverse, ...
            'tcsview', 'T', 'background', handles.image, ...
            'structures', handles.image.structures, ...
            'slider', handles.trans_slider, 'cbar', 'off', 'pixelval', 'on');

        % Initialize coronal viewer
        handles.cplot = ImageViewer('axis', handles.coronal, ...
            'tcsview', 'C', 'background', handles.image, ...
            'structures', handles.image.structures, ...
            'slider', handles.cor_slider, 'cbar', 'off', 'pixelval', 'on');

        % Initialize sagittal viewer
        handles.splot = ImageViewer('axis', handles.sagittal, ...
            'tcsview', 'S', 'background', handles.image, ...
            'structures', handles.image.structures, ...
            'slider', handles.sag_slider, 'cbar', 'on', 'pixelval', 'on');
    end
    
    % If struct_table exist
    if isfield(handles.image, 'structures') && ...
            ~isempty(handles.image.structures) && ...
            isfield(handles, 'dose') && ~isempty(handles.dose)

        % Initialize DVH plot and table
        handles.dplot = DVHViewer('axis', handles.dvh, ...
            'structures', handles.image.structures, 'doseA', handles.dose, ...
            'table', handles.struct_table, 'columns', 4);
        set(handles.struct_table, 'visible', 'on');
    end
end

% Clear temporary variables
clear imagefiles rtssfiles dosefiles path;