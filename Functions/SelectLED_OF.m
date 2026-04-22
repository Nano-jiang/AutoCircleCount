%% SelectLED_OF


% 统计文件夹中的视频数
% 指定 behavCam*.avi 文件夹路径

% 获取以 behavCam开头，.avi 结尾的文件列表
files = dir(fullfile(currentFile, 'behavCam*.avi'));

% 计算视频文件数量
behavCamNumber = length(files);

disp(['文件夹中共有 ', num2str(behavCamNumber), ' 个 behavCam 视频文件。']);

%% 创建一个存储所有视频文件名的单元数组
behavCamFiles = cell(behavCamNumber, 1);

% 依次填充视频文件名到数组中
for i = 1:behavCamNumber
    behavCamFiles{i} = sprintf('behavCam%d.avi', i);
end

%% 将behavCam文件按照顺序排列

% 获取文件列表
behavCamFiles = dir('behavCam*.avi');

% 提取文件名
fileNames = {behavCamFiles.name};

% 使用正则表达式提取文件名中的数字: (\d+), tokens: 返回捕获组的内容
fileNums = regexp(fileNames, 'behavCam(\d+)\.avi', 'tokens');

% 将嵌套的元胞数组转换为数字数组
% 语法：cellfun(func, C)，其中 func 是要应用的函数，C 是单元格数组
fileNums = cellfun(@(x) str2double(x{1}), fileNums);

% 按照数字对文件名进行排序
[~, sortIdx] = sort(fileNums);

% 重新排列文件列表
behavCamFiles = behavCamFiles(sortIdx);

selectedFrameInfo = struct('videoFile', '', 'frameNumber', []);

%% 通过框 Red LED 获取框选区 roi 的位置
% 初始化窗口位置和大小变量
windowPosition = [];

% 遍历每个视频文件，选择红色LED出现的帧
for vi = 1:behavCamNumber
    videoFile = behavCamFiles(vi).name;
    videoObj = VideoReader(videoFile);
    numFrames = videoObj.NumFrames;
    
    % 从视频文件的第一帧开始，每隔50帧处理一次
    for frameNumber = 1:50:numFrames
        frame = read(videoObj, frameNumber);
        
        % 创建显示窗口
        fig = figure('Name', 'Frame Selection', 'WindowStyle', 'normal');
        if ~isempty(windowPosition)
            set(fig, 'Position', windowPosition);
        end
        imshow(frame);
        
        % 获取用户输入
        prompt = '是否根据此帧选择红色的LED区域？（请选择 yes/no）: ';
        userInput = input(prompt, 's');
        
        % 记录窗口位置和大小
        windowPosition = get(fig, 'Position');
        
        if strcmpi(userInput, 'yes') || strcmpi(userInput, 'y')
            selectedFrameInfo.videoFile = videoFile;
            selectedFrameInfo.frameNumber = frameNumber;
            title('请框选LED区域');
            h = imrect;
            roi = round(getPosition(h)); % 使用imrect获取用户框选的矩形区域
            close(fig);
            break;
        else
            close(fig);
        end
    end
    
    % 如果用户已经选择了一帧，则退出所有循环
    if ~isempty(selectedFrameInfo.videoFile)
        break;
    end
end

% 输出选择的帧信息
if ~isempty(selectedFrameInfo.videoFile)
    fprintf('选择的帧来自文件 %s 的第 %d 帧\n', selectedFrameInfo.videoFile, selectedFrameInfo.frameNumber);
else
    fprintf('没有选择任何帧\n');
end

save('LED_selection.mat');
movefile('LED_selection.mat', 'FrameCount2');
