%% zoneDividing_OF_Multi3
% 选择一个正方形区域，以选择矩形的最长边作为正方形边长

currentFile = pwd;
mkdir('FrameCount2');

%% Select a square region of view
videoPath = 'behavCam1.avi';
video = VideoReader(videoPath);

firstFrame = readFrame(video);

disp('Please select the Open Field area');
imshow(firstFrame);

% Drawn area
h = drawrectangle('AspectRatio', 1);
wait(h);
pos = h.Position;  % [xmin, ymin, width, height]
close(gcf);

%% Forcibly correct to a square (taking the smaller side)
xmin_OF = pos(1);
ymin_OF = pos(2);
sideLength = max(pos(3), pos(4));

width_OF = sideLength;
height_OF = sideLength;

%% Display the corrected square area
imshow(firstFrame);
rectangle('Position', [xmin_OF ymin_OF width_OF height_OF], ...
          'EdgeColor', 'b', 'FaceColor', [0 0 1 0.3]);
hold on;

Region_OF = [xmin_OF ymin_OF width_OF height_OF];

save('Region_OF.mat','Region_OF');
movefile('Region_OF.mat', 'FrameCount2');