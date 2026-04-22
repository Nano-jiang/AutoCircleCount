%% AutoFrameCount_CF_New

close all; clear; clc

%% 预加载项

% 弹出选择对话框，初始位置设为当前路径
selPath = uigetdir(pwd, '请选择包含视频文件的文件夹');

% 检查用户是否取消了选择
if isequal(selPath, 0)
    disp('用户取消了文件夹选择。脚本停止运行。');
    return;
else
    fprintf('已选择文件夹: %s\n', selPath);
    % 将当前工作路径切换到选中的文件夹
    cd(selPath); 
    currentFile = selPath;
end

zoneDividing_OF_Multi3
SelectLED_OF

currentFile = pwd;
targetFolder = fullfile(currentFile, 'FrameCount2');

load(fullfile(targetFolder, 'Region_OF.mat'));
load(fullfile(targetFolder, 'LED_selection.mat'));

%% 小鼠路径识别

mouseTracking_redLED_Multi_OF
load(fullfile(targetFolder, 'mouseTrajectory.mat'));
