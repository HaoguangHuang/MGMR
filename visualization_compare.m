%1.tracking4, frame16
%2.child_no1, frame16
%3.dog_no_1,  frame01
function visualization_compare
    rectScale = 1.2;
    series_mat = {'toy_wg_occ','child_no1','dog_no_1'};
    frames_mat = [16,16,1];
    f_num = length(series_mat);
    for i = 1:f_num
        rgb = imread(sprintf('./RGB_data/%s/%02d.png',series_mat{i},frames_mat(i)));
        MGMR_mask = imread(sprintf('./hhg_algorithm/output_20180209_1110/%s/pt_0/%02d.png',series_mat{i},frames_mat(i)));
        gt_mask = imread(sprintf('./Label/%s/%02d_obj_1.png',series_mat{i},frames_mat(i)));
        obj_based_mask = imread(sprintf('./our_result/%s/%02d_mask_2.png',series_mat{i},frames_mat(i)));
        
        boundingBox = getBox(gt_mask);
        biggerBox = scaleBox(boundingBox,rectScale);
        
        x = biggerBox(1); y = biggerBox(2);
        w = biggerBox(3); h = biggerBox(4);
        x_end = x + w;
        y_end = y + h;
        [H,W] = size(gt_mask);
        if x<1, x = 1; end
        if y<1, y = 1; end
        if x_end>W, x_end = W; end
        if y_end>H, y_end = H; end
        
%         figure(i+20);
%         subplot(1,4,1);
%         imshow(uint8(rgb(y:y_end,x:x_end,:))),title(sprintf('%s,frame %d, rgb',series_mat{i},frames_mat(i)));
%         subplot(1,4,2);
%         imshow(gt_mask(y:y_end,x:x_end)),title(sprintf('%s,frame %d, gt_mask',series_mat{i},frames_mat(i)));
%         subplot(1,4,3);
%         imshow(MGMR_mask(y:y_end,x:x_end)),title(sprintf('%s,frame %d, MGMR_mask',series_mat{i},frames_mat(i)));
%         subplot(1,4,4);
%         imshow(obj_based_mask(y:y_end,x:x_end)),title(sprintf('%s,frame %d, obj_based_mask',series_mat{i},frames_mat(i)));
%         
        output_dir = sprintf('./visualizationCompareRes/eg%d_%s_frame%02d',i,series_mat{i},frames_mat(i));
        if ~exist(output_dir), mkdir(output_dir); end
        imwrite(uint8(rgb(y:y_end,x:x_end,:)),sprintf('%s/eg%d_rgb.png',output_dir,i));
        imwrite(gt_mask(y:y_end,x:x_end),sprintf('%s/eg%d_gtMask.png',output_dir,i));
        imwrite(MGMR_mask(y:y_end,x:x_end),sprintf('%s/eg%d_MGMR_mask.png',output_dir,i));
        imwrite(obj_based_mask(y:y_end,x:x_end),sprintf('%s/eg%d_obj_based_mask.png',output_dir,i));
        
        
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function box = getBox(mask)
   stats = regionprops(mask,'boundingbox');
   box_n = size(stats,1);
    if box_n > 1
       %choose the largest box
       box_array = zeros(box_n,4);
       for i = 1:box_n,box_array(i,:) = stats(i).BoundingBox; end
       box_area = box_array(:,3).*box_array(:,4);
       [~,idx] = max(box_area);
       box = round(stats(idx).BoundingBox);
    else
       box = round(stats.BoundingBox);
    end
%     figure(5),imshow(mask,[]);hold on;
%     rectangle('position',box,'edgeColor','r','lineWidth',3);
%     hold off;
end

%make the boundingBox bigger
%rS:rectangle scale parameter
function rectOut = scaleBox(rectIn, rS)
    r_m = round([rectIn(1)+rectIn(3)/2, rectIn(2)+rectIn(4)/2]); %rectangle middle
    w = rS*rectIn(3);
    h = rS*rectIn(4);
    x = r_m(1) - w/2;
    y = r_m(2) - h/2;
    if x<=0, x=1; end
    if y<=0, y=1; end
    rectOut = round([x,y,w,h]);
end