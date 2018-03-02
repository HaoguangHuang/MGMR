function maskOut = segmentation_opt(d, y, rectIn, id, norm_box_sz)
    global debug_mode;
    r_m = round([rectIn(1)+rectIn(3)/2, rectIn(2)+rectIn(4)/2]); %rectangle middle

    scale_num = 3;
    cnt = 1;
    
    truncate_d = [0.4,0.5,0.5];
    truncate_c = [0.5,0.5,0.5];
    winsz_array = [9,9,5];
    
    scale_min = norm_box_sz/max(rectIn(1,3:4));
    scale_array = linspace(scale_min,1,scale_num);

    sigma_d = 1.4e-5 * d(r_m(2),r_m(1)) * d(r_m(2),r_m(1));    
    sigma_c = 10;
    
    mask_c = histFind(d, rectIn, sigma_d);
    
    if debug_mode 
        I(:,:,1) = mat2gray(mask_c)*255;
        I(:,:,2) = y;
        I(:,:,3) = zeros(size(y));
        figure(70),imshow(uint8(I));
    end
    a = tic;
    while cnt <= scale_num
        scale = scale_array(cnt);
        d_down = imresize(d,scale,'nearest');
        y_down = imresize(y,scale,'nearest');
        mask_down = imresize(mask_c,size(d_down),'nearest');
        rect = round(rectIn * scale);
        winsz = winsz_array(cnt);
        if ~mod(winsz,2), winsz = winsz + 1; end
        if cnt <= 1
            mask_d = mask_down;
        else
            mask_d = depth_jbf(d_down,id,mask_down,rect,y_down,truncate_d(cnt),winsz,sigma_d);
        end
        
        mask_c = color_jbf(y_down,id,mask_d,rect,truncate_c(cnt),winsz,sigma_c);
        cnt = cnt + 1;
    end
    b = toc(a);
    disp(['depth, sum(t) = ',num2str(b)]);
    maskOut = mask_c;
    
end


function mask_c = histFind(d, rectIn, sigma_d)
    lower = 500; upper = 4000;
    interval = 10;
    x = rectIn(1);
    y = rectIn(2);
    w = rectIn(3);
    h = rectIn(4);
    border_w = x+w; border_h = y+h;
    if border_h>size(d,1), border_h = size(d,1); end
    if border_w>size(d,2), border_w = size(d,2); end
    d_rect = d(y:border_h,x:border_w);
    d_vec = reshape(d_rect,1,size(d_rect,1)*size(d_rect,2));
    
    mask_rect = zeros(size(d));
    mask_rect(y:border_h,x:border_w) = 1;
    
    tic;
    hmap = hist(d_vec, lower:interval:upper);
    [~, id]= max(hmap(1,2:end-1));
    d_max = lower + id*interval;
    d_lower = d_max - 3 * sigma_d;
    d_upper = d_max + 3 * sigma_d;
    mask_c = d > d_lower & d < d_upper & mask_rect;
    t = toc; %second
    t_mean = t/(rectIn(3)*rectIn(4));
    disp(['histogram per pixel time = ',num2str(t_mean)]);
end