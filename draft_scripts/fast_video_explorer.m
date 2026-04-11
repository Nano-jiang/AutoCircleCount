%%

function fast_video_explorer()
    %% 1. 批量加载视频数据 (建议内存充足时使用)
    numFiles = 30;
    allFrames = {};
    fprintf('正在加载视频文件...\n');
    
    try
        for i = 1:numFiles
            fileName = sprintf('behavCam%d.avi', i);
            if exist(fileName, 'file')
                vr = VideoReader(fileName);
                % read() 将视频一次性读入内存，提升跳转速度
                tempData = read(vr); 
                allFrames{i} = tempData;
                fprintf('已加载: %s\n', fileName);
            end
        end
    catch ME
        error('加载失败，请检查文件是否存在或内存是否足够：\n%s', ME.message);
    end

    if isempty(allFrames), error('未找到任何视频文件'); end

    %% 2. 构建界面
    % 使用  辅助理解布局
    fig = uifigure('Name', 'Behavior Video Explorer', 'Position', [100 100 800 600]);
    ax = uiaxes(fig, 'Position', [50 120 700 450]);
    
    % 初始化显示第一段视频的第一帧
    currentVideoIdx = 1;
    imgHandle = imshow(allFrames{currentVideoIdx}(:,:,:,1), 'Parent', ax);
    title(ax, sprintf('Current Video: behavCam%d.avi', currentVideoIdx));

    %% 3. 交互控件
    % 视频切换下拉菜单
    dropdown = uidropdown(fig, 'Position', [50 60 150 25], ...
        'Items', arrayfun(@(x) sprintf('behavCam%d.avi', x), 1:numFiles, 'UniformOutput', false), ...
        'ValueChangedFcn', @(src, event) changeVideo(src.Value));

    % 帧跳转滑块
    sld = uislider(fig, 'Position', [220 70 530 3], ...
        'Limits', [1, size(allFrames{currentVideoIdx}, 4)], ...
        'Value', 1, ...
        'ValueChangedFcn', @(src, event) updateFrame(), ...
        'ValueChangingFcn', @(src, event) updateFrame(event.Value)); % 拖动时实时更新

    % 帧数显示
    lbl = uilabel(fig, 'Position', [220 40 200 25], 'Text', 'Frame: 1');

    %% 4. 回调函数
    function changeVideo(val)
        % 提取文件名中的数字
        currentVideoIdx = str2double(regexp(val, '\d+', 'match', 'once'));
        numFrames = size(allFrames{currentVideoIdx}, 4);
        
        % 重置滑块范围
        sld.Limits = [1, numFrames];
        sld.Value = 1;
        
        title(ax, sprintf('Current Video: %s', val));
        updateFrame(1);
    end

    function updateFrame(manualVal)
        if nargin < 1
            fIdx = round(sld.Value);
        else
            fIdx = round(manualVal);
        end
        
        % 核心优化：直接更改 CData 句柄，不重新渲染整个坐标轴
        imgHandle.CData = allFrames{currentVideoIdx}(:,:,:,fIdx);
        lbl.Text = sprintf('Frame: %d / %d', fIdx, size(allFrames{currentVideoIdx}, 4));
    end
end
