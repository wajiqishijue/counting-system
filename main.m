clear; clc; close all;
[filename, pathname] = uigetfile({'*.jpg;*.png;*.bmp;*.tif;*.jpeg'}, '请选择包含多个目标的图片');
if isequal(filename, 0)
    fprintf('用户取消选择，程序退出。\n');
    return;
end
image_path = fullfile(pathname, filename);
fprintf('已加载图片：%s\n', filename);
I_original = imread(image_path);
if size(I_original, 3) == 3
    I_gray = rgb2gray(I_original);
else
    I_gray = I_original;
end
level = graythresh(I_gray);
I_bw = im2bw(I_gray, level);
se = strel('square', 3);
I_bw = imopen(I_bw, se); 
I_bw = imclose(I_bw, se);  
[L, num] = bwlabel(I_bw);   
stats = regionprops(L, 'Area', 'BoundingBox', 'Centroid');
min_area = 100;  
valid_idx = find([stats.Area] >= min_area);
num_valid = length(valid_idx);
fprintf('检测到 %d 个连通域，过滤后有效目标 %d 个\n', num, num_valid);
if num_valid == 0
    fprintf('?? 未检测到有效目标！请检查图片是否对比度清晰，或调小 min_area 值。\n');
    imshow(I_original); title('未检测到目标，请换图或调整参数');
    return;
end
valid_bbox = zeros(num_valid, 4);
valid_centroid = zeros(num_valid, 2);
for i = 1:num_valid
    idx = valid_idx(i);
    valid_bbox(i, :) = stats(idx).BoundingBox;
    valid_centroid(i, :) = stats(idx).Centroid;
end
figure('Name', '多目标计数结果', 'Position', [50, 50, 1000, 800]);
subplot(2, 2, 1);
imshow(I_original);
title('1. 原始图像');
subplot(2, 2, 2);
imshow(I_bw);
title('2. 二值化 + 去噪');
subplot(2, 2, 3);
imshow(I_original);
hold on;
for i = 1:num_valid
    rectangle('Position', valid_bbox(i, :), 'EdgeColor', 'r', 'LineWidth', 2);
    text(valid_bbox(i, 1), valid_bbox(i, 2) - 5, num2str(i), ...
        'Color', 'y', 'FontSize', 14, 'FontWeight', 'bold', ...
        'BackgroundColor', 'black');

    plot(valid_centroid(i, 1), valid_centroid(i, 2), 'g+', 'MarkerSize', 10, 'LineWidth', 2);
end
title(sprintf('3. 计数结果：共 %d 个目标', num_valid));
hold off;
subplot(2, 2, 4);
areas = [stats(valid_idx).Area];
histogram(areas, 10);
xlabel('目标面积 (像素)');
ylabel('数量');
title('4. 各目标面积分布');
grid on;
fprintf('\n========== 目标位置信息表 ==========\n');
fprintf('编号\t 质心X\t 质心Y\t 宽度\t 高度\n');
for i = 1:num_valid
    fprintf(' %d\t %.1f\t %.1f\t %.1f\t %.1f\n', i, ...
        valid_centroid(i, 1), valid_centroid(i, 2), ...
        valid_bbox(i, 3), valid_bbox(i, 4));
end
fprintf('=======================================\n');
fprintf('? 总计检测到 %d 个目标\n', num_valid);