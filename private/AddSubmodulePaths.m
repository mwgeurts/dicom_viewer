function AddSubmodulePaths(config)
% AddSubModulePaths is called by DicomViewer during initialization
% to add all submodule paths and verify the submodule functions are
% present.
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

% Add archive extraction tools submodule to search path
addpath(config.DICOM_TOOLS);

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

% Add tcs_plots submodule to search path
addpath('./tcs_plots');

% Check if MATLAB can find @ImageViewer
if exist('ImageViewer', 'class') ~= 8
    
    % If not, throw an error
    Event(['The tcs_plots submodule does not exist in the ', ...
        'search path. Use git clone --recursive or git submodule init ', ...
        'followed by git submodule update to fetch all submodules'], ...
        'ERROR');
end