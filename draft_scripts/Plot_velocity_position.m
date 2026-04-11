
% 绘制小鼠的速率随位置的变化

% data working path: E:\CircleField\M3_CF\251224_M3_CF\FrameCount2
clear
close all
clc


%%
load('mouseTrajectory.mat');
load('Region_OF.mat');

width_cm = 30;
height_cm = 30;
width_pixel = Region_OF(3);
height_pixel = Region_OF(4);

% 平滑路径（防抖）
sigma = 3;
positions_smoothed(:, 1) = imgaussfilt(positions(:, 1), sigma);
positions_smoothed(:, 2) = imgaussfilt(positions(:, 2), sigma);

positions_cm(:,1) = abs(positions_smoothed(:,1) - Region_OF(1))* width_cm / width_pixel;
positions_cm(:,2) = abs(positions_smoothed(:,2) - Region_OF(2))* height_cm / height_pixel;

x1 = positions_cm(:,1);
y1 = positions_cm(:,2);

% figure
% plot(x1,y1);
% x1_center = mean(x1);
% y1_center = mean(y1);
% hold on
% scatter(15,15,'o');
% hold off

%% 计算小鼠运动速度（矢量）
fps = 30;
frameNum = size(positions_cm,1);
velocity = zeros(frameNum, 1);

    for i = 1:frameNum-1
        dx = x1(i+1) - x1(i);
        dy = y1(i+1) - y1(i);
        velocity(i) = sqrt(dx^2 + dy^2) * fps;
    end
    velocity(end) = velocity(end-1);

%% 小鼠所在位置弧度的变化

center = [15, 15]; % 角度中心

% 2. 计算相对位移
% 将坐标原点平移到中心点 (15, 15)
dx_angle = x1 - center(1);
dy_angle = y1 - center(2);

% 3. 计算角度
% 使用 atan2(dy, dx) 得到的是与正东方向(x正半轴)的弧度，范围为 [-pi, pi]
% 我们需要计算与“右下角”(dx>0, dy<0)的方向夹角，且为顺时针
% 一个简单的方法是：先计算标准极坐标，再通过旋转和翻转调整

% 标准角度（逆时针，0度在右侧）
theta_rad = atan2(dy_angle, dx_angle); 
theta_deg = rad2deg(theta_rad);

% 转换逻辑：
% 目标：右下角为0度，顺时针增加。
% 右下角在标准坐标系中大约是 -45度（或315度）。
% 顺时针意味着我们需要对标准角度取负。
adjusted_angles = theta_deg - 45;

% 4. 统一到 [0, 359] 范围内
final_angles = mod(adjusted_angles, 360);

% 5. 绘图
figure('Color', 'w');
frames = 1:frameNum;
plot(frames, final_angles(frames) ./ 6, 'LineWidth', 1, 'Color', [0, 0.4470, 0.7410]);
hold on
plot(frames, velocity(frames),'LineWidth', 1, 'Color', [0.46, 0.67, 0.19]);
hold off

grid on;
xlabel('帧数 (Frame)');
ylabel('角度 (Degrees)');
title('小鼠每一帧的顺时针角度位置');
axis([1 frameNum 0 60]); % 设置y轴范围
set(gca, 'ytick', 0:45:360); % 每45度显示一个刻度

