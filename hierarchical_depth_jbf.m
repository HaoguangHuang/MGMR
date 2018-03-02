function maskOut = hierarchical_depth_jbf(fu_fg_d, k, maskIn, mask_middle,rectIn,y,norm_box_sz)
        global debug_mode; 

        %%
        %第一次执行
        scale_num = 3;
        sigma_d_array = [3,5,7];
        
%         if  min(rectIn(1,3:4)) - norm_box_sz < 20
%             winsz_array = linspace(5,3,scale_num); %small object
%         else
%             winsz_array = linspace(7,3,scale_num);
%         end
        winsz_array = linspace(7,3,scale_num);
        scale_min = norm_box_sz/min(rectIn(1,3:4));
        scale_array = linspace(scale_min,1,scale_num);
        
        truncate_array = [0.4, 0.5, 0.6];
       
        cnt = 1;
        mask_down = maskIn;
        while cnt <= scale_num
            weight_i = zeros(1,1);
            count_jbf = 0;
            sigma_d = sigma_d_array(cnt);
            win_width = winsz_array(cnt);
            if ~mod(win_width,2), win_width = win_width + 1; end
            truncated_thres = truncate_array(cnt);
            scale = scale_array(cnt);%(0,1]

            fg_down = imresize(fu_fg_d,scale,'nearest');
            y_d = imresize(y,scale,'nearest');
            mask_down = imresize(mask_down,size(fg_down),'nearest');
            rect = round(scale*rectIn);
            [~, weight_o,~,weight_s]= guided_jbf_princeton_d(mask_down, fg_down,-1,count_jbf, weight_i,sigma_d,win_width,...
                truncated_thres,0,rect,y_d);          
            count_jbf = count_jbf + 1;
            g_thres = 0;%guided thres------per pixel
            g_t = inf;    
            
            while 1
                [mask_down, ~, g_t,~] = guided_jbf_princeton_d(mask_down, fg_down, -1, count_jbf, weight_o,sigma_d,...
                    win_width,truncated_thres,weight_s,rect,y_d);            
                if g_t <= g_thres
                    disp(['frame ',int2str(k), '------------total for ', int2str(count_jbf), ' times!']);
                    break;
                end
                disp(['g_t = ',int2str(g_t), ', now is ' ,int2str(count_jbf), 'th circle time']);
                fprintf('depth resolution = %d*%d,scale=%d\n',size(mask_down,1),size(mask_down,2),scale_num-cnt+1);
                count_jbf = count_jbf + 1;
            end
            
            if debug_mode
                I = [];
                I(:,:,1) = mat2gray(mask_down)*255;
                I(:,:,2) = mat2gray(y_d)*255;
                I(:,:,3) = zeros(size(fg_down));
                figure(77),imshow(uint8(I),[]),title(sprintf('%d*%d,mask after depth jbf,scale=%d\n',size(fg_down,1),size(fg_down,2),scale_num-cnt+1));
            end
            
        end
        maskOut = mask_down;
%         mask_GF = guidedfilter(double(fu_fg_d),double(mask),win_width,0.01);

end