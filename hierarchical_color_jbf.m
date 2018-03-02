function maskOut = hierarchical_color_jbf(fu_fg_c, k, maskIn, rectIn)
    global debug_mode;
    
    sigma_c = 10;
    scale_num = 1;
%     scale_num = log(scale)/log(2)+1;

    win_width = max(round(0.05*min(rectIn(1,3:4))),3);
    if ~mod(win_width,2), win_width = win_width+1; end
    truncate_thres = 0.5;
    
    cnt = 1;
    while cnt <= scale_num
        count_jbf = 0;%第一次执行
        weight_i = zeros(1,1);
        rect = rectIn;
        mask_down = maskIn;
        fg_down = fu_fg_c;
        [~, weight_o,~,weight_s]= guided_jbf_princeton_c(mask_down,fg_down,-1,count_jbf,weight_i,sigma_c,win_width,truncate_thres,0,rect);%这里只是计算了weight_o
        count_jbf = count_jbf + 1;
        g_thres = 5;%guided thres------per pixel
        g_t = inf;
        
        while 1
            [mask_down, ~, g_t,~] = guided_jbf_princeton_c(mask_down,fg_down,-1,count_jbf,weight_o,sigma_c,win_width,truncate_thres,weight_s,rect);
            if g_t <= g_thres
                disp(['frame ',int2str(k), '------------total for ', int2str(count_jbf), ' times!']);
                break;
            end
            count_jbf = count_jbf + 1;
            disp(['g_t = ',int2str(g_t), ', now is ' ,int2str(count_jbf), 'th time']);
            fprintf('color resolution = %d*%d\n',size(mask_down,1),size(mask_down,2));
        end
        
        cnt = cnt + 1;
    end
    maskOut = mask_down;

    
end