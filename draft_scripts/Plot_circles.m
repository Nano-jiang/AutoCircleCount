
% 绘制挑选出来的trial

trialFrames = [qualified_lap_indices_start, qualified_lap_indices_end];
trial_start = trialFrames(:,1);
trial_end = trialFrames(:,2);

%% 仅绘制路径
x1 = positions_cm(:,1);
y1 = positions_cm(:,2);

trialNum = length(trialFrames);

% % 1. 自动计算布局（例如：尽量接近正方形的布局）
% cols = ceil(sqrt(trialNum)); 
% rows = ceil(trialNum / cols);
% 
% figure; % 只创建一个画布
% 
% for ti = 1:trialNum
%     % 2. 使用 subplot 切换到第 ti 个子图区域
%     subplot(rows, cols, ti);
% 
%     % 3. 进行绘图
%     plot(x1(trial_start(ti):trial_end(ti)), y1(trial_start(ti):trial_end(ti)));
% 
%     % 设置坐标轴范围
%     xlim([0 30]);
%     ylim([0 30]);
%     axis equal tight;
%     set(gca, 'YDir', 'reverse');
%     axis off;
%     % 可选：加上标题方便区分
%     title(['Trial ', num2str(ti)]);
% end

%% 绘制彩色速率路径
% 获取全局速度范围用于归一化
max_v = max(velocity);
min_v = min(velocity);

% 1. 自动计算布局
cols = ceil(sqrt(trialNum)); 
rows = ceil(trialNum / cols);

figure; % 创建白色背景画布

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
    axis equal tight;
    set(gca, 'YDir', 'reverse');
    axis off;
    
    title(['Trial ', num2str(ti)], 'FontSize', 8);
end

% ... 前方的循环绘图代码保持不变 ...

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
