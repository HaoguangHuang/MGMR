function makeVideo
    clear all;
    para.fps = 24;    %Hz
    para.gt_stop = 1.5; %second
    
    %---get gt
    [gt_mat, idx_gt] = getGT();
    %---get MGMR result
    [seg_mat, idx_seg] = getSeg();
    %---make video
    make_video(seg_mat, idx_seg, gt_mat, idx_gt, para);
end

function [gt_mat, idx_gt] = getGT()
    gtAddress = './hhg_algorithm/output_videosegmentation_hhg/child_no1/gt';
    gt_fname = dir(sprintf('%s/*.png',gtAddress));
    fnum = size(gt_fname,1);
    gt_mat = cell(fnum,2);
    idx_gt = zeros(fnum,1);
    for i= 1:fnum
        gt_fname(i).id = sscanf(gt_fname(i).name,'%03d.png');
        gt_mask = imread(sprintf('%s/%s',gtAddress,gt_fname(i).name));
        gt_mat{i,1} = gt_mask; gt_mat{i,2} = gt_fname(i).id;
        idx_gt(i) = gt_fname(i).id;
    end
    gt_mat = sortrows(gt_mat,2);
    idx_gt = sortrows(idx_gt,1);
end

function [seg_mat, idx_seg] = getSeg()
    segAddress = './hhg_algorithm/output_videosegmentation_hhg/child_no1/segRes';
    seg_fname = dir(sprintf('%s/*.png',segAddress));
    fnum = size(seg_fname,1);
    seg_mat = cell(fnum,2);
    idx_seg = zeros(fnum,1);
    for i = 1:fnum
        seg_fname(i).id = sscanf(seg_fname(i).name,'%03d.png');
        seg = imread(sprintf('%s/%s',segAddress,seg_fname(i).name));
        seg_mat{i,1} = seg; seg_mat{i,2} = seg_fname(i).id;
        idx_seg(i) = seg_fname(i).id;
    end
    seg_mat = sortrows(seg_mat,2);
    idx_seg = sortrows(idx_seg,1);
end

function make_video(seg_mat, idx_seg, gt_mat, idx_gt, para)
    idx_video = 1;
    fps = para.fps;         %Hz
    gt_stop = para.gt_stop; %second
    
    gt_frame_length = round(fps*gt_stop);
    
    v = VideoWriter('./hhg_algorithm/output_videosegmentation_hhg/videoFile/video.avi','Uncompressed AVI');
    v.FrameRate = fps;
    open(v);
    for i_seg = idx_seg'
        i_gt = find(idx_gt==i_seg);
        I = seg_mat{i_seg,1};
        if ~isempty(i_gt) %encounter groundtruth
            k = 0;
            gt_mask = gt_mat{i_gt,1};
           
            g = I(:,:,2); g(gt_mask>0) = 255;
            I(:,:,2) = g;
            while k < gt_frame_length
                writeVideo(v,uint8(I));
                k = k + 1;
                idx_video = idx_video + 1;
            end
        end
        writeVideo(v,uint8(I));
        idx_video = idx_video + 1;
    end
    close(v);
end

