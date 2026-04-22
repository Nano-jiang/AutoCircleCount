
%% 计算两个坐标点之间的欧几里得距离

function distance = calculateDistance(point1, point2)
    % point1 和 point2 是 1x2 的向量，分别表示两个点的 [x, y] 坐标
    distance = sqrt((point2(1) - point1(1))^2 + (point2(2) - point1(2))^2);
end