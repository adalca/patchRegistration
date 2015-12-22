% required toolboxes:
% - adalca's main toolboxes: mgt, patchlib, mvit
% - view3D (TODO: make this optional)


%% setup paths

% get username
[~, whoami] = system('whoami');
whoami = strrep(whoami, '\', '/');
spl = strsplit(whoami, '/');
usrname = spl{end}; 

% constants
if ispc % windows paths
    OUTPUT_PATH = 'D:/Dropbox (MIT)/Research/patchRegistration/output/';
    if strncmp(usrname, 'abobu', 5) 
        BUCKNER_PATH = 'Windows/path/to/data';
        BUCKNER_ATLAS_PATH = '';
        
    else
        assert(strncmp(usrname, 'adalca', 6) )
        PREBUCKNER_PATH = 'D:/Dropbox (MIT)/Public/robert/buckner';
        BUCKNER_PATH = 'D:\Dropbox (MIT)\Research\patchSynthesis\data\buckner\proc';
        BUCKNER_ATLAS_PATH = 'D:\Dropbox (MIT)\Research\patchSynthesis\data\buckner\atlases\';
        TOOLS_PATH = 'C:\Users\adalca\Dropbox (Personal)\MATLAB\toolboxes';
        EXTLIB_PATH = 'C:\Users\adalca\Dropbox (Personal)\MATLAB\external_toolboxes';
    end

else % unix/mac paths
    OUTPUT_PATH = '/data/vision/polina/scratch/abobu/patchRegistration/output/';
    if strncmp(usrname, 'abobu', 5)
        PREBUCKNER_PATH = '/afs/csail.mit.edu/u/a/abobu/toolbox/buckner/';
        BUCKNER_PATH = '/data/vision/polina/scratch/adalca/patchSynthesis/data/buckner/proc/';
        BUCKNER_ATLAS_PATH = '/data/vision/polina/scratch/adalca/patchSynthesis/data/buckner/atlases/';
        TOOLS_PATH = '/afs/csail.mit.edu/u/a/abobu/toolbox';
        EXTLIB_PATH = '/afs/csail.mit.edu/u/a/abobu/toolbox';
    else
        assert(strncmp(usrname, 'adalca', 6) )
        BUCKNER_PATH = '/data/vision/polina/scratch/adalca/patchSynthesis/data/buckner/proc';
        BUCKNER_ATLAS_PATH = '/data/vision/polina/scratch/adalca/patchSynthesis/data/buckner/atlases/';
        TOOLS_PATH = '/data/vision/polina/users/adalca/MATLAB/toolboxes';
        EXTLIB_PATH = '/data/vision/polina/users/adalca/MATLAB/external_toolboxes';
    end
end

%% add paths as necessary
VIEW_PATH = fullfile(EXTLIB_PATH, 'view3D'); 
UGM_PATH = fullfile(EXTLIB_PATH, 'UGM'); 
addpath(genpath(TOOLS_PATH));
addpath(genpath(VIEW_PATH));
addpath(genpath(UGM_PATH));
addpath(genpath(fileparts(mfilename('fullpath'))));


%% settings
warning off backtrace; % turn off backtrace for warnings.
