%% AutoCircleCount_CF

% %% 代码说明：
% 根据小鼠在环形场中的"角度变化曲线"和"速率变化曲线"
% 自动筛选合格的圈（每一圈作为一个trial）
% 并绘制每一圈的实际路径，并将对应的速率以色彩表示（红 fast → 紫 slow）

% %% 代码标注：
% WXW
% 2026/1/19 version 1.1（1.0+）

% %% 工作流程：
% 运行全部 → 接着运行 433 行
% 得到4+1张图片，特别关注前三张figure
% 自动保存 FrameCount.xlsx (圈数始末统计表，最重要！！)
% 注意命令行 "符合面积条件的圈数" 是否与实际相符
% 通过figure 3的彩色圈数，确认是否需要手动删除那些小鼠临时停下吃蹦出奶球的圈数
% 通过figure 5（不被保存）确认上一步手动挑选的圈数是否已经扣除

% %% 可调参数：
% 筛选窗口秒数 2-30 s 在 97 行可以修改
% 考虑不同小鼠完成一圈的时间可能存在较大差异
% 一般完成得快 2 s 足够，完成得慢需要 30 s
% 所以这一步是给完成圈数一个时间阈值

%%
clear
close all
clc

%% 加载路径等数据
currentFolder = pwd;
targetFolder = fullfile(currentFolder, 'FrameCount2');

load(fullfile(targetFolder, 'Region_OF.mat'));
load(fullfile(targetFolder, 'mouseTrajectory.mat'));

width_cm = 30; height_cm = 30;
width_pixel = Region_OF(3); height_pixel = Region_OF(4);

% 平滑路径
sigma = 3;
positions_smoothed(:, 1) = imgaussfilt(positions(:, 1), sigma);
positions_smoothed(:, 2) = imgaussfilt(positions(:, 2), sigma);
positions_cm(:,1) = abs(positions_smoothed(:,1) - Region_OF(1))* width_cm / width_pixel;
positions_cm(:,2) = abs(positions_smoothed(:,2) - Region_OF(2))* height_cm / height_pixel;
x1 = positions_cm(:,1);
y1 = positions_cm(:,2);

%% 计算速率与角度
fps = 30;
frameNum = size(positions_cm,1);

dx = diff(x1); 
dy = diff(y1);
velocity = [sqrt(dx.^2 + dy.^2) * fps; sqrt(dx(end).^2 + dy(end).^2) * fps]; % 单位: cm/s，末尾补0

% 计算角度：右下角为0，顺时针增加
center = [width_cm/2, height_cm/2];
dx_angle = x1 - center(1);
dy_angle = y1 - center(2);
theta_deg = rad2deg(atan2(dy_angle, dx_angle));
adjusted_angles = theta_deg - 45; 
final_angles = mod(adjusted_angles, 360);

%% 在计算出 velocity 和 final_angles 之后运行以下筛选代码

% 1. 识别所有跳变尖峰（过线时刻：角度从 ~359 降至 ~0）
peak_indices = find(diff(final_angles) < -300);

% 2. 初始化存储筛选结果的变量
qualified_lap_indices_end = []; % 存储符合条件的尖峰帧号
all_lap_areas = [];         % 记录每一圈的面积，便于后续调试分析

% 3. 循环分析每一圈的面积（按照peak初步筛选）
start_idx = 1; 

for i = 1:length(peak_indices)
    end_idx = peak_indices(i);

    % 提取当前这一圈（从 0 度增加到 359 度）的速率数据
    current_lap_v = velocity(start_idx:end_idx);

    % 使用梯形积分计算曲线下面积 (AUC)
    % 注意：如果 velocity 单位是 cm/s，trapz 结果需除以 fps 才是实际厘米数
    current_area = trapz(current_lap_v) /30;
    all_lap_areas(i) = current_area;

    % 一圈的运动路程：速率曲线下面积在 80 到 180 之间
    % 90 ≈ 30 * 3.14 即贴着内圆跑
    if current_area >= 60 && current_area <= 200
        qualified_lap_indices_end = [qualified_lap_indices_end; end_idx];
    end

    start_idx = end_idx + 1;
end

%% 寻找符合条件的起点 qualified_lap_indices_start

qualified_lap_indices_start = []; 
final_qualified_ends = []; 

% 用 2 s 的窗口筛除折返峰
window_size = 2; 

for i = 1:length(qualified_lap_indices_end)
    curr_end = qualified_lap_indices_end(i);
    
    % 1. 寻找起点 (峰值出现前 2-30 s)
    search_start = max(1, curr_end - 30*fps);
    search_end = curr_end - 2*fps;
    if search_end < 1, continue; end
    
    search_range = search_start : search_end;
    % 9 为角度，一般小鼠在起点出发的角度在该值以下轻微波动
    valid_start_candidates = search_range((final_angles(search_range) > 0) & (final_angles(search_range) <= 9));
    
    if ~isempty(valid_start_candidates)
        best_start = max(valid_start_candidates);
        
        % 提取该完整区间的角度序列
        lap_angles = final_angles(best_start : curr_end);
        
        % --- 关键逻辑：限制时间窗口内的逆时针跌幅 ---
        % 计算滑动窗口内的“累计最高点”
        local_max = movmax(lap_angles, [window_size*fps 0]);
        
        % 计算当前帧相对于之前窗口内最高点的跌幅
        % 如果跌幅 > 30°，说明在 2 s 内出现了剧烈的逆时针回退
        drop_value = local_max - lap_angles;
        
        if all(drop_value <= 30)
            qualified_lap_indices_start = [qualified_lap_indices_start; best_start];
            final_qualified_ends = [final_qualified_ends; curr_end];
        end
    end
end

% 更新终点列表
qualified_lap_indices_end = final_qualified_ends;

%% 进一步筛选速率曲线下峰面积
all_lap_areas2 = [];
qualified_lap_indices_start2 = [];
qualified_lap_indices_end2 = [];

for i = 1:length(qualified_lap_indices_end)
    start_idx2 = qualified_lap_indices_start(i);
    end_idx2 = qualified_lap_indices_end(i);

    % 提取当前这一圈（从 0 度增加到 359 度）的速率数据
    current_lap_v2 = velocity(start_idx2:end_idx2);

    % 使用梯形积分计算曲线下面积 (AUC)
    % 注意：如果 velocity 单位是 cm/s，trapz 结果需除以 fps 才是实际厘米数
    current_area2 = trapz(current_lap_v2) /30;
    all_lap_areas2(i) = current_area2;

    % 一圈的运动路程：速率曲线下面积在 60 到 200 之间
    % 90 ≈ 30 * 3.14 即贴着内圆跑
    % 由于视频畸变，需要调整下限阈值
    if current_area2 >= 60 && current_area2 <= 200
        qualified_lap_indices_start2 = [qualified_lap_indices_start2; start_idx2];
        qualified_lap_indices_end2 = [qualified_lap_indices_end2; end_idx2];
    end
end

%% 可视化结果
figure(1);
set(gcf, 'Color', 'w', 'Units', 'normalized', 'Position', [0.1, 0.4, 0.7, 0.4]);

% --- 子图 1: 角度曲线 ---
ax1 = subplot(2,1,1);
plot(final_angles, 'Color', [0.5 0.5 0.5]); hold on;
% 绘制所有尖峰（灰色小点）
% plot(peak_indices, final_angles(peak_indices), 'o', 'Color', [0.8, 0.8, 0.8], 'MarkerSize', 4);
% 绘制符合条件的起点和终点
if ~isempty(qualified_lap_indices_end2)
    plot(qualified_lap_indices_start2, final_angles(qualified_lap_indices_start2), 'bo', 'MarkerFaceColor', 'b', 'MarkerSize', 6);
    plot(qualified_lap_indices_end2, final_angles(qualified_lap_indices_end2), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 6);
    % 在每一个点上方标记序号 (1-n)
    num = length(qualified_lap_indices_start2);
    for i = 1:num
        % text(x坐标, y坐标 + 偏移量, 字符串内容)
        % 'HorizontalAlignment', 'center' 确保文字水平居中
        text(qualified_lap_indices_end2(i), final_angles(qualified_lap_indices_end2(i)) + 15, ...
            num2str(i), 'Color', 'k', 'FontSize', 9, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    end
    % 遍历每一组起点和终点，绘制阴影区间
    for k = 1:length(qualified_lap_indices_end2)
        idx_start = qualified_lap_indices_start2(k);
        idx_end = qualified_lap_indices_end2(k);
        
        % 提取该区间的 X 和 Y 数据
        x_patch = idx_start:idx_end;
        y_patch = final_angles(x_patch);
        
        % 构造填充多边形的顶点：
        % 先顺着曲线走 (x, y)，再绕回到起点 (x_end->x_start, 0)
        X_fill = [x_patch, fliplr(x_patch)];
        Y_fill = [y_patch', zeros(1, length(x_patch))]; % 确保是行向量拼接
        
        % 绘制填充区域
        fill(X_fill, Y_fill, [0, 0, 1], ...     % 红色填充
            'FaceAlpha', 0.3, ...               % 透明度设置为 0.3
            'EdgeColor', 'none', ...            % 不显示边缘线
            'HandleVisibility', 'off');         % 不在图例中显示每一个色块
    end
end
hold off;
grid on; ylabel('角度 (°)'); 
title(['角度尖峰识别 (共 ', num2str(length(qualified_lap_indices_end2)), ' 圈)']);

% --- 子图 2: 速率曲线 ---
ax2 = subplot(2,1,2);
plot(velocity, 'Color', [116/255, 165/255, 218/255], 'LineWidth', 1); hold on;

if ~isempty(qualified_lap_indices_end2)
    % 遍历每一组起点和终点，绘制阴影区间
    for k = 1:length(qualified_lap_indices_end2)
        idx_start = qualified_lap_indices_start2(k);
        idx_end = qualified_lap_indices_end2(k);
        
        % 提取该区间的 X 和 Y 数据
        x_patch = idx_start:idx_end;
        y_patch = velocity(x_patch);
        
        % 构造填充多边形的顶点：
        % 先顺着曲线走 (x, y)，再绕回到起点 (x_end->x_start, 0)
        X_fill = [x_patch, fliplr(x_patch)];
        Y_fill = [y_patch', zeros(1, length(x_patch))]; % 确保是行向量拼接
        
        % 绘制填充区域
        fill(X_fill, Y_fill, [1, 0, 0], ...     % 红色填充
            'FaceAlpha', 0.3, ...               % 透明度设置为 0.3
            'EdgeColor', 'none', ...            % 不显示边缘线
            'HandleVisibility', 'off');         % 不在图例中显示每一个色块
    end
    
    % 额外绘制起终点的边界线（可选，增强视觉感）
    line([qualified_lap_indices_start2'; qualified_lap_indices_start2'], ...
         [zeros(size(qualified_lap_indices_start2')); velocity(qualified_lap_indices_start2)'], ...
         'Color', 'b', 'LineWidth', 1);
    line([qualified_lap_indices_end2'; qualified_lap_indices_end2'], ...
         [zeros(size(qualified_lap_indices_end2')); velocity(qualified_lap_indices_end2)'], ...
         'Color', 'r', 'LineWidth', 1);
end
hold off;
grid on; ylabel('速率'); xlabel('帧数 (Frame)');
title('速率曲线 (红色垂线为终点)');

% --- 核心：调整子图高度和间距 ---
% Position 格式为 [左, 下, 宽, 高]
h = 0.35;      % 适当增加高度比例（0.15太扁，文字会重叠）
w = 0.92;      % 增加宽度比例，减少左右留白（0.92 是一个极限值）
left_margin = 0.06; % 减小左侧边距

% --- 调整子图 1 ---
% [左, 下, 宽, 高]
ax1.Position = [left_margin, 0.55, w, h]; 

% --- 调整子图 2 ---
% 将下边界设得更低，减少底部留白
ax2.Position = [left_margin, 0.12, w, h]; 

% --- 移除多余的 X 轴刻度标签 ---
% 如果两个子图的 X 轴是一样的，可以隐藏第一个子图的标签以节省空间
set(ax1, 'XTickLabel', []); 
xlabel(ax1, ''); % 移除第一个子图的 xlabel
% 命令行反馈
fprintf('分析完成，好耶！！ ヽ(✿ﾟ▽ﾟ)ノ \n');
fprintf('初筛得到的所有圈数: %d\n', length(qualified_lap_indices_end));
fprintf('符合面积条件的圈数: %d\n', length(qualified_lap_indices_end2));

%% 绘制符合条件的每一圈（包括可能需要手动删除的圈数）
trialFrames = [qualified_lap_indices_start2, qualified_lap_indices_end2];
trial_start = trialFrames(:,1);
trial_end = trialFrames(:,2);

trialNum = length(trialFrames);

% %% 绘制彩色速率路径
% 获取全局速度范围用于归一化
max_v = max(velocity);
min_v = min(velocity);

% 1. 自动计算布局
cols = ceil(sqrt(trialNum)); 
rows = ceil(trialNum / cols);

figure(2); clf;
set(gcf, 'Color', 'w', 'Units', 'normalized', 'Position', [0.1, 0.1, 0.7, 0.6]);

for ti = 1:trialNum
    subplot(rows, cols, ti);
    
    % 提取当前圈的数据
    idx = trial_start(ti):trial_end(ti);
    curr_x = x1(idx);
    curr_y = y1(idx);
    curr_v = velocity(idx);
    
    % --- 核心修改：使用彩色线条绘制 ---
    % 创建一个表面对象，Z 轴设为 0，颜色映射到速度 C
    % 'EdgeColor', 'interp' 能够实现平滑的色彩过渡
    z = zeros(size(curr_x)); % Z轴分量
    surface([curr_x, curr_x], [curr_y, curr_y], [z, z], [curr_v, curr_v], ...
        'FaceColor', 'none', ...
        'EdgeColor', 'interp', ...
        'LineWidth', 1.5);
    
    % --- 设置色彩映射 (Colormap) ---
    % 依照你的要求：快->红，慢->紫
    % HSV 色彩空间的切换：紫色对应约 0.75, 红色对应 0 或 1
    % 或者直接使用内置的 'jet' 或 'turbo' (紫色到红色)
    colormap(turbo); 
    clim([min_v max_v]);
    
    % 设置坐标轴
    xlim([0 30]);
    ylim([0 30]);
    axis equal;
    set(gca, 'YDir', 'reverse');
    axis off;
    
    title(['Trial ', num2str(ti) ' (', num2str(trial_start(ti)), ')'], 'FontSize', 8);
end
% --- 添加整个大图的总标题 ---
sgtitle('合格跑圈', 'FontSize', 12, 'FontWeight', 'bold', 'FontName', 'Microsoft YaHei');

% --- 调整 Colorbar 到右下角 ---
% 参数解释：[距离左侧90%, 距离底部5%, 宽度2%, 高度15%]
cb = colorbar;
set(cb, 'Units', 'normalized', ...
        'Position', [0.92, 0.05, 0.015, 0.15], ... 
        'FontSize', 7);

% 设置颜色映射：紫色到红色
% turbo 默认是从深蓝/紫到红，非常适合
colormap(turbo); 

% 统一所有子图的速度量程
clim([min_v max_v]); 

% 给 colorbar 加个简短的标题
title(cb, 'v(cm/s)', 'FontSize', 8);

FrameCount = trialFrames;
filename = 'FrameCount.xlsx';

% 写入文件
writematrix(FrameCount, filename);
fprintf('文件成功保存至: FrameCount.xlsx\n');

%% 绘制被淘汰的每一圈
unqualified_lap_indices_start = setdiff(qualified_lap_indices_start, qualified_lap_indices_start2);
unqualified_lap_indices_end = setdiff(qualified_lap_indices_end, qualified_lap_indices_end2);

trialFrames_un = [unqualified_lap_indices_start, unqualified_lap_indices_end];
trial_start = trialFrames_un(:,1);
trial_end = trialFrames_un(:,2);

trialNum = size(trialFrames_un,1);

if trialNum >= 1
% 1. 自动计算布局
cols = ceil(sqrt(trialNum)); 
rows = ceil(trialNum / cols);

figure(3); clf;
set(gcf, 'Color', 'w', 'Units', 'normalized', 'OuterPosition', [0.1 0.1 0.4 0.3]); % 创建白色背景画布

for ti = 1:trialNum
    subplot(rows, cols, ti);
    
    % 提取当前圈的数据
    idx = trial_start(ti):trial_end(ti);
    curr_x = x1(idx);
    curr_y = y1(idx);
    curr_v = velocity(idx);
    
    % --- 核心修改：使用彩色线条绘制 ---
    % 创建一个表面对象，Z 轴设为 0，颜色映射到速度 C
    % 'EdgeColor', 'interp' 能够实现平滑的色彩过渡
    z = zeros(size(curr_x)); % Z轴分量
    surface([curr_x, curr_x], [curr_y, curr_y], [z, z], [curr_v, curr_v], ...
        'FaceColor', 'none', ...
        'EdgeColor', 'interp', ...
        'LineWidth', 1.5);
    
    % --- 设置色彩映射 (Colormap) ---
    % 依照你的要求：快->红，慢->紫
    % HSV 色彩空间的切换：紫色对应约 0.75, 红色对应 0 或 1
    % 或者直接使用内置的 'jet' 或 'turbo' (紫色到红色)
    colormap(turbo); 
    clim([min_v max_v]);
    
    % 设置坐标轴
    xlim([0 30]);
    ylim([0 30]);
    axis equal;
    set(gca, 'YDir', 'reverse');
    axis off;
    
    title(['Trial ', num2str(ti)], 'FontSize', 8);
end

% --- 调整 Colorbar 到右下角 ---
% 参数解释：[距离左侧90%, 距离底部5%, 宽度2%, 高度15%]
cb = colorbar;
set(cb, 'Units', 'normalized', ...
        'Position', [0.92, 0.05, 0.015, 0.15], ... 
        'FontSize', 7);

% 设置颜色映射：紫色到红色
% turbo 默认是从深蓝/紫到红，非常适合
colormap(turbo); 

% 统一所有子图的速度量程
clim([min_v max_v]); 

% 给 colorbar 加个简短的标题
title(cb, 'v(cm/s)', 'FontSize', 8);

% --- 添加整个大图的总标题 ---
sgtitle('删除的跑圈', 'FontSize', 12, 'FontWeight', 'bold', 'FontName', 'Microsoft YaHei');
else
    figure(3); clf;
end

return

% %% 接着运行下面的代码
% %% //////////////////////////////////////////////////////////////////
% %% //////////////////////////////////////////////////////////////////

%% 将每一圈的角度和对应的速率绘制出来
% x: 角度（°）
% y: 速率（cm/s）

filename = 'FrameCount.xlsx';
FrameCount = readmatrix(filename); % 筛选后的trials

% 1. 定义箱体边界和中心点
bin_width = 6;
edges = 0:bin_width:360;            % 箱体边界：0, 2, 4...
bin_centers = edges(1:end-1) + bin_width/2; % 箱体中心：1, 3, 5... (用于绘图)

% 2. 收集所有合格圈数的数据点
all_x = [];
all_y = [];

for ti = 1:size(FrameCount, 1)
    start_idx = FrameCount(ti, 1);
    end_idx = FrameCount(ti, 2);
    
    all_x = [all_x; final_angles(start_idx:end_idx)];
    all_y = [all_y; velocity(start_idx:end_idx)];
end

% 3. 计算每个区间 [bin_low, bin_high) 的平均值
mean_velocity_bins = zeros(size(bin_centers));

for j = 1:length(bin_centers)
    % 找到落在当前区间 [edges(j), edges(j+1)) 内的所有索引
    idx_in_bin = (all_x >= edges(j)) & (all_x < edges(j+1));
    
    if any(idx_in_bin)
        % 计算该区间内所有点的平均速率
        mean_velocity_bins(j) = mean(all_y(idx_in_bin));
    else
        mean_velocity_bins(j) = NaN; % 如果该区间没采样到数据，设为 NaN
    end
end

% 4. 绘图
figure(4); clf;
set(gcf, 'Color', 'w');

% 绘制原始所有点的散点（可选，设为非常淡的灰色以观察分布）
scatter(all_x, all_y, 1, [0.8 0.8 0.8], 'filled', 'MarkerEdgeAlpha', 0.1); 
hold on;

% 绘制区间平均曲线
plot(bin_centers, mean_velocity_bins, 'Color', [0.8500 0.3250 0.0980], 'LineWidth', 2.5);

% 5. 装饰美化
xlabel('Degree (°)'); ylabel('Mean velocity (cm/s)');
title('所有跑圈的区间平均速率');
xlim([0 360]); ylim([0 50]);
xticks(0:60:360);
xticklabels({'0°','60°','120°','180°','240°','300°','360°'});
grid on;

legend('All Data Points', 'Bin Average', 'Location', 'northeast');

% 1. 定义文件夹名称和文件名
folder_name = 'FrameCount2';
file_name = 'averaged_velocity_bin.mat';

% 2. 检查文件夹是否存在，如果不存在则创建
if ~exist(folder_name, 'dir')
    fprintf('文件夹 FrameCount2 不存在 (⊙o⊙)？\n');
    return
end

% 3. 构建完整保存路径
save_path = fullfile(folder_name, file_name);

% 4. 保存变量到指定的 mat 文件中
save(save_path, 'bin_centers', 'mean_velocity_bins');

% 5. 命令行反馈
fprintf('速率数据已成功保存至: %s\n', save_path);

%% 自动保存所有图片至 FrameCount2 文件夹
fprintf('正在保存图片...\n');

names = {'fig1_峰值-速率曲线', 'fig2_合格跑圈', 'fig3_删除跑圈', 'fig4_平均速率曲线'};

for i = 1:4
    % 检查该编号的窗口是否存在
    if ishandle(i)
        hFig = figure(i); % 激活对应的窗口
        drawnow;         % 强制刷新布局
        
        saveName = fullfile(folder_name, [names{i}, '.png']);
        
        % 导出图片
        exportgraphics(hFig, saveName, 'Resolution', 300, 'ContentType', 'image');
        fprintf('  [已保存]: %s\n', names{i});
    else
        fprintf('  [跳过]: 未发现 Figure %d\n', i);
    end
end

%% 验证手动删除圈是否被删除 (图片不被保存)

% filename = 'FrameCount.xlsx';
% FrameCount = readmatrix(filename);
trialNum = size(FrameCount,1);
cols = ceil(sqrt(trialNum)); 
rows = ceil(trialNum / cols);

figure;

for ti = 1:trialNum
    trial_start = FrameCount(ti,1);
    trial_end = FrameCount(ti,2);
    subplot(rows, cols, ti);
    plot(x1(trial_start:trial_end), y1(trial_start:trial_end));

    % 设置坐标轴范围
    xlim([0 30]);
    ylim([0 30]);
    axis equal tight;
    set(gca, 'YDir', 'reverse');
    axis off;
    % 可选：加上标题方便区分
    title(['Trial ', num2str(ti)]);
end
