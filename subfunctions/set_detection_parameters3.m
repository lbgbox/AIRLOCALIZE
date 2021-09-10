function [params,alData] = set_detection_parameters3(params)

% initialize params structure and set to defaults if needed. (otherwise
% values left in previous call to the function are used as the defaults)
if ~isa(params,'airLocalizeParams') 
    params = airLocalizeParams();
    params.reset();
end

%% choose the mode (single file vs. directory)
disp('setting detection mode...');
params = set_detection_mode3(params);
if strcmp(params.fileProcessingMode,'cancel'), return; end
params.checkParamsConsistency([],'detection_mode');

%% pick file or directory
disp('picking input file or dir...');
params = get_image_file_location(params);
if strcmp(params.fileProcessingMode,'cancel'), return; end

%% get file list 
disp('collecting list of files to analyze...');
alData = airLocalizeData();
alData.setFListFromParams(params);
if isempty(alData.getFList)
    disp('could not find files to analyze.');
    return
else
    disp(['Found ',num2str(numel(alData.getFList)),' files to analyze.']);
end
% if empty, default saving dir to the dir holding the first image in the
% list
if isempty(params.saveDirName)
    params.saveDirName = fileparts(alData.fList{1});
end

%% set movie mode
if contains(params.fileProcessingMode,'movie') ...
        || contains(params.fileProcessingMode,'Movie')
    alData.isMovie = 1;
end

%% get data dimensionality
disp('setting data dimensionality...');
params = params.getNumDim(alData.getFList);
if strcmp(params.fileProcessingMode,'cancel'), return;  end
disp(['data is ',num2str(params.numDim),'D.']);
params.checkParamsConsistency(alData,'numDim');

%% set parameters
disp('setting detection parameters...');
params = detection_parameters_interface6(params);
if strcmp(params.fileProcessingMode,'cancel'), return; end
params.checkParamsConsistency(alData,'detection_parameters_interface');

%% set PSF width manually (optional)
alData.setFileIdx(1);
if params.setPsfInteractively == 1
    disp('setting PSF size interactively...');
    [params,alData] = set_psf_size_manually(params,alData);
end
if strcmp(params.fileProcessingMode,'cancel'), return; end

%% set Int threshold manually (optional) 
alData.setFileIdx(1);
if params.setThreshInteractively  == 1 
   disp('setting threshold interactively...');
   params = set_threshold_manually(params,alData); 
end
if strcmp(params.fileProcessingMode,'cancel'), return; end

end

%% subfunctions

function params = get_image_file_location(params)
% sets a pop up that collects the name of the file or directory to analyze.
if ismember(params.fileProcessingMode,{'singleFile','singleFileMovie'})
    [fname,sourceDir,fidx] = uigetfile('*.tif;*.stk;*.lsm','Select Source Image File');
    if fidx == 0, params.fileProcessingMode = 'cancel'; return; end
    params.dataFileName = fullfile(sourceDir,fname);
    
elseif ismember(params.fileProcessingMode,{'batch','movieInDir','batchMovie'})
    sourceDir = uigetdir('','Select Source Images Directory');
    if sourceDir == 0, params.fileProcessingMode = 'cancel'; return; end
    params.dataFileName = sourceDir;
end

params.saveDirName = sourceDir;

clear('fname','sourcedir','fidx');
end
