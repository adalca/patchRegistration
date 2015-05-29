% required toolboxes:
% - adalca's main toolboxes: mgt, patchlib, mvit
% - view3D (TODO: make this optional)

%% Set up paths;
EXTLIB_PATH = 'C:\Users\adalca\Dropbox (Personal)\MATLAB\external_toolboxes';
TOOLS_PATH = 'C:\Users\adalca\Dropbox (Personal)\MATLAB\toolboxes';
VIEW_PATH = fullfile(EXTLIB_PATH, 'view3D'); 
UGM_PATH = fullfile(EXTLIB_PATH, 'UGM'); 

%% add paths
addpath(genpath(TOOLS_PATH));
addpath(genpath(VIEW_PATH));
addpath(genpath(UGM_PATH));
addpath(genpath(fileparts(mfilename('fullpath'))));

%% Data paths
BUCKNER_PATH = 'D:\Research\patchSynthesis\data\buckner';
BUCKNER_ATLAS_PATH = 'D:\Research\data\buckner\atlases\';
