% clear all;
function main
    warning off;
    global debug_mode; debug_mode = 0;
    addpath('./hhg_algorithm');
    addpath(genpath('./Eval_code'));
    series_mat = {'zcup_move_1','child_no1','tracking4','toy_wg_occ','dog_no_1'};
%     series_mat = {'zcup_move_1'};
    rectScale = 1.2;
    norm_box_sz = 100;
    pixel_trslation = 0:2:30; %boundingBox translation
%     trans_array = [1,0;0,1;-1,0;0,-1];
    trans_num = 20;
    for i = 1:size(series_mat,2)
        series = series_mat{i};
        [box_mat, idx, gt_mat]= getGT(series);       %idx:tell which maps should be catched in getDepth and getY
        d_mat = getDepth(series, idx);      %{dmap}
        y_mat = getY(series, idx);          %{ymap}
        if size(d_mat,1) == size(y_mat,1)
            fnum = size(d_mat,1);
        else
            error('depthmap num is not equal to ymap num!');
        end

        %------check source data
%         for i = 1:fnum
%             d = d_mat{i,1}; y = y_mat{i,1}; box = box_mat(i,1:4);
%             figure(7),imshow(d,[]); rectangle('position',box,'edgeColor','r','lineWidth',3);
%             figure(8),imshow(y,[]); rectangle('position',box,'edgeColor','r','lineWidth',3);
%         end
        
        t = fix(clock);
        for pt = pixel_trslation
            outputDir = sprintf('./hhg_algorithm/output/%s/pt_%d',series,pt);
            if ~exist(outputDir,'dir'), mkdir(outputDir); end
            
            if pt == 0 
                vis_Dir = sprintf('%s/vis',outputDir);
                if ~exist(vis_Dir,'dir'), mkdir(vis_Dir); end
                IOU_array = zeros(fnum,1);
                for n = 2:fnum%1:fnum
                    id = idx(n);
                    box = box_mat(n,1:4);
                    boxBigger = scaleBox(box, rectScale);
                    if boxBigger(1) <= 0, boxBigger(1) = 0; end
                    if boxBigger(2) <= 0, boxBigger(2) = 0; end
                    if debug_mode 
                        figure(6),imshow(y_mat{n,1},[]);hold on;
                        rectangle('position',box,'edgeColor','r','linewidth',2);
                        rectangle('position',boxBigger,'edgeColor','g','linewidth',2);
                        hold off;
                    end
%                     mask = segmentation(double(d_mat{n,1}),y_mat{n,1}(:,:,1),boxBigger,id,norm_box_sz);
                    mask = segmentation_opt(double(d_mat{n,1}),y_mat{n,1}(:,:,1),boxBigger,id,norm_box_sz);
                    
                    
                    I(:,:,1) = mat2gray(mask)*255;
                    I(:,:,2) = y_mat{n,1}(:,:,1);
                    I(:,:,3) = zeros(size(mask));
                    if debug_mode
                        figure(90),imshow(uint8(I)),title('segmentation result');
                    end
                    IOU_score = Compute_IOU( mask, gt_mat{n,1} );
                    IOU_array(n) = IOU_score;
                    imwrite(logical(mask),sprintf('%s/%02d.png',outputDir,id));
                    imwrite(uint8(I),sprintf('%s/%02d.png',vis_Dir,id));
                end
                fprintf('------pt=%d, IOU avg of %s is %05.2f------',pt,series,mean(IOU_array));

                fid = fopen(sprintf('%s/IOU_res.txt',outputDir),'a');
                if fid > 0
                    fprintf(fid,'%s    %d-%02d-%02d %02d:%02d:%02d\n',series,t(1),t(2),t(3),t(4),t(5),t(6));
                    for k = 1:size(IOU_array,1)
                        fprintf(fid,'frame %d : %05.2f\n',idx(k),IOU_array(k));
                    end
                    fprintf(fid,'IOU avg:%05.2f\n',mean(IOU_array));
                    fprintf(fid,'-------------------------------\n');
                end
                fclose(fid);
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            else %pt>0
                IOU_array = zeros(fnum,trans_num);
                rng(pt); theta = randi([0,360],trans_num,1);
                trans_array = [sin(theta/180*pi), cos(theta/180*pi)];
                for n = 1:fnum
                    id = idx(n);
                    box = box_mat(n,1:4);
                    boxBigger = scaleBox(box, rectScale);
                    for t_n = 1:trans_num
                        trans = trans_array(t_n,:);
                        trans = trans*pt;
                        box_trans = [round(boxBigger(1)+trans(1)),...
                                    round(boxBigger(2)+trans(2)),...
                                    boxBigger(3),...
                                    boxBigger(4)];
                        if box_trans(1) <= 0, box_trans(1) = 0; end
                        if box_trans(2) <= 0, box_trans(2) = 0; end
                        if debug_mode
                            figure(6),imshow(y_mat{n,1},[]);hold on;
                            rectangle('position',box,'edgeColor','r','linewidth',2);
                            rectangle('position',boxBigger,'edgeColor','g','linewidth',2);
                            rectangle('position',box_trans,'edgeColor','b','linewidth',2);
                            title(sprintf('box(r),boxBigger(g),box_trans(b),pt=[%d,%d]',box_trans(1),box_trans(2)));
                            hold off;
                        end
%                         mask = segmentation(double(d_mat{n,1}),y_mat{n,1}(:,:,1),box_trans,id,norm_box_sz);
                        mask = segmentation_opt(double(d_mat{n,1}),y_mat{n,1}(:,:,1),box_trans,id,norm_box_sz);
                            I(:,:,1) = mat2gray(mask)*255;
                            I(:,:,2) = y_mat{n,1}(:,:,1);
                            I(:,:,3) = zeros(size(mask));
                        if debug_mode
                            figure(90),imshow(uint8(I)),title(sprintf('pt=[%d,%d],segmentation result',box_trans(1),box_trans(2)));
                        end
                        IOU_score = Compute_IOU( mask, gt_mat{n,1} );
                        IOU_array(n,t_n) = IOU_score;
                        
                        mask_dir = sprintf('%s/tn%d',outputDir,t_n);
                        I_dir = sprintf('%s/vis',mask_dir);
                        
                        if ~exist(mask_dir,'dir'), mkdir(mask_dir); end
                        if ~exist(I_dir,'dir'), mkdir(I_dir); end
                        imwrite(logical(mask),sprintf('%s/%02d.png',mask_dir,id));
                        imwrite(uint8(I),sprintf('%s/%02d.png',I_dir,id));
                    end
                end
                IOU_mean_array = mean(IOU_array,2);
                fprintf('------pt=%d, IOU avg of %s is %05.2f------',pt, series,mean(IOU_mean_array));

                fid = fopen(sprintf('%s/IOU_res.txt',outputDir),'a');
                if fid > 0
                    fprintf(fid,'%s    %d-%02d-%02d %02d:%02d:%02d\n',series,t(1),t(2),t(3),t(4),t(5),t(6));
                    for k = 1:size(IOU_mean_array,1)
                        fprintf(fid,'frame %d : %05.2f\n',idx(k),IOU_mean_array(k));
                    end
                    fprintf(fid,'IOU avg:%05.2f\n',mean(IOU_mean_array));
                    fprintf(fid,'-------------------------------\n');
                end
                fclose(fid);
            end
        end
    end
    
    %------Evaluation
%     IOU_score = Compute_IOU( result_img, gt_label );
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

function y_mat = getY(series, idx)
    c_fname = dir(sprintf('./RGB_data/%s/*.png',series));
    fnum = size(c_fname,1);
    y_array = cell(fnum,2);
    for i = 1:fnum
        c_fname(i).id = sscanf(c_fname(i).name,'%02d.png');
        c = imread(sprintf('./RGB_data/%s/%s',series,c_fname(i).name));
        y = rgb2ycbcr(c);
        y_array{i,1} = y; y_array{i,2} = c_fname(i).id;
    end
    y_array = sortrows(y_array,2);
    y_mat = y_array(idx,:);
end


function d_mat = getDepth(series, idx)
    d_fname = dir(sprintf('./Depth_data/%s/*.mat',series));
    fnum = size(d_fname,1);
    d_array = cell(fnum,2); %[map,idx]
    for i = 1:fnum
        d_fname(i).id = sscanf(d_fname(i).name,'%02d.mat');
%         eval(sprintf('load ./Depth_data/%s/%s depth',series,d_fname(i).name));
        eval(sprintf('load ./Depth_data/%s/%s depth_org',series,d_fname(i).name));
        d_array{i,1} = depth_org;
        d_array{i,2} = d_fname(i).id;
    end
    d_array = sortrows(d_array,2);
    d_mat = d_array(idx,:); %d_mat:n*2 cell
end

function [box_mat, idx, gt_mat]= getGT(series)
%     fileAddr = sprintf('./Label/%s',series);
    gt_fname = dir(sprintf('./Label/%s/*.png',series));
    fnum = size(gt_fname,1);
    box_mat = zeros(fnum,5); %[x, y, w, h, id]
    gt_mat = cell(fnum,2);
    for i= 1:fnum
        gt_fname(i).id = sscanf(gt_fname(i).name,'%02d_obj_1.png');
        gt_mask = imread(sprintf('./Label/%s/%s',series,gt_fname(i).name));
        gt_mat{i,1} = gt_mask; gt_mat{i,2} = gt_fname(i).id;
        box = getBox(logical(gt_mask));
        box_mat(i,:) = [box,gt_fname(i).id];
    end
    box_mat = sortrows(box_mat,5);
    idx = box_mat(:,5);
    gt_mat = sortrows(gt_mat,2);
end

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


