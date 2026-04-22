%% mouseTracking_redLED_Multi_OF

% 对每一帧小鼠位置识别进行了优化（采用3点平均）

%% 计算像素点颜色

selectFrame = frame;

% 提取框选区域中的颜色信息
ledRegion = selectFrame(roi(2):roi(2)+roi(4)-1, roi(1):roi(1)+roi(3)-1, :);

% 计算每个像素与红色的差异
considerRed = [255, 130, 165]; % origin
% considerRed = [255, 100, 100]; % 更加接近于实际的红色
diff = sqrt(sum((double(ledRegion) - reshape(considerRed, [1 1 3])).^2, 3));

% 找到差异最小的10个像素点
[~, sortedIdx] = sort(diff(:));
numPixels = 10; % 取最接近红色的10个像素点
selectedIdx = sortedIdx(1:numPixels);

% 获取这些像素点的颜色值
[rows, cols] = ind2sub(size(diff), selectedIdx);
selectedColors = zeros(numPixels, 3);
for i = 1:numPixels
    selectedColors(i, :) = ledRegion(rows(i), cols(i), :);
end

% 计算这10个像素点的平均颜色
ledColor = mean(selectedColors, 1);

% 初始化一些变量
positions = []; % 用于存储小鼠位置
threshold = 30; % 颜色匹配的阈值，可以调整

%% 创建一个图像句柄和轨迹句柄
figure;
hIm = imshow(selectFrame);
hold on;
hPlot = plot(NaN, NaN, 'r.');

% 遍历视频帧
previousPosition = [];

% % Tmaze_division中已经定义了S1, S2, S3的范围
Region_OFround = round(Region_OF);

% 创建一个与frame大小相同的逻辑矩阵，初始化为false
mask = false(size(frame, 1), size(frame, 2));

% 将OF范围内的像素置为true, 目的是排除led映射在墙面上的红色被纳入运算
mask(Region_OFround(2):Region_OFround(2)+Region_OFround(4)-1, Region_OFround(1):Region_OFround(1)+Region_OFround(3)-1) = true;

for vi = 1:behavCamNumber
    video = behavCamFiles(vi).name;
    vid = VideoReader(video);
    frameNum = vid.NumFrames;

    for i = 1:frameNum

        frame = read(vid, i);
                
        % 计算每个像素与LED颜色的差异，但仅限于mask为true的位置
        diff = sqrt(sum((double(frame) - reshape(ledColor, [1 1 3])).^2, 3));
        diff(~mask) = inf; % mask为false的位置设为inf，不参与后续计算
        
        % 找到颜色差异最小的3个点的坐标
        [minDiffs, idx] = mink(diff(:), 3);
        currentPositions = NaN(3, 2);
        for j = 1:3
            if minDiffs(j) < threshold
                [y, x] = ind2sub(size(diff), idx(j));
                currentPositions(j, :) = [x, y]; % 记录当前帧的位置
            else
                currentPositions(j, :) = [NaN, NaN]; % 无效位置
            end
        end

        
        % 若3个点都不是NaN，分别计算两两之间的距离
        point1 = currentPositions(1,:);
        point2 = currentPositions(2,:);
        point3 = currentPositions(3,:);
        ledRegion = 10; % Red LED 的像素长宽一般不会大于这个值

        if all([~isnan(point1), ~isnan(point2), ~isnan(point3)])
            distance12 = calculateDistance(point1,point2);
            distance13 = calculateDistance(point1,point3);
            distance23 = calculateDistance(point2,point3);
            if all([(distance12 <= ledRegion), (distance13 <= ledRegion), (distance23 <= ledRegion)])
                currentPosition = (point1 + point2 + point3)/3;
            else
                currentPosition = [NaN,NaN];
            end           
        else
            currentPosition = [NaN,NaN];
        end
                
        positions = [positions; currentPosition];

        previousPosition = currentPosition; % 更新前一帧的位置
        
        % 更新图像和轨迹
        set(hIm, 'CData', frame);
        
        % 只显示最近100帧的轨迹
        if size(positions, 1) > 100
            recentPositions = positions(end-99:end, :);
        else
            recentPositions = positions;
        end
        set(hPlot, 'XData', recentPositions(:, 1), 'YData', recentPositions(:, 2));
        
        drawnow;
    end
end
hold off;
title('小鼠运动轨迹');

%% 插值填充 NaN
nanInd = any(isnan(positions), 2); % 找到包含 NaN 的行
positions(nanInd, :) = interp1(find(~nanInd), positions(~nanInd, :), find(nanInd), 'linear'); % 使用线性插值填充 NaN
% positions = round(positions);

% 填充 NaN
nanInd = any(isnan(positions), 2); % 找到包含 NaN 的行
for i = 1:length(nanInd)
    if nanInd(i)
        if i == 1
            % positions(i, :) = round(positions(find(~nanInd, 1, 'first'), :));
            positions(i, :) = (positions(find(~nanInd, 1, 'first'), :));
        else
            % positions(i, :) = round(positions(i - 1, :));
            positions(i, :) = (positions(i - 1, :));
        end
    end
end

%% 绘制小鼠原始路径
x = positions(:,1);
y = positions(:,2);

% figure
% plot(x,y);

%% 用高斯滤波对小鼠路径进行平滑处理
% 高斯滤波器
sigma = 3; 
% 默认1.5更加合适
% 2026/1/19 改为 3
positions_smoothed(:, 1) = imgaussfilt(positions(:, 1), sigma);
positions_smoothed(:, 2) = imgaussfilt(positions(:, 2), sigma);

x_smoothed = positions_smoothed(:, 1);
y_smoothed = positions_smoothed(:, 2);

figure
plot(x_smoothed, y_smoothed);

%%
save("mouseTrajectory.mat","positions","positions_smoothed");
movefile('mouseTrajectory.mat', 'FrameCount2');

