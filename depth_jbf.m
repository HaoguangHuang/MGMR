function maskOut = depth_jbf(d,id,maskIn,rect,y,thres,winsz,sigma_d)
    weight_i = zeros(1,1);
    count_jbf = 0;
    
    [~, weight_o,~,weight_s]= guided_jbf_princeton_d(maskIn,d,-1,count_jbf, weight_i,sigma_d,winsz,...
                thres,0,rect,y);          
    count_jbf = count_jbf + 1;
    g_thres = 10;%guided thres------per pixel
    g_t = inf;   
    
    while 1
        [maskIn, ~, g_t,~] = guided_jbf_princeton_d(maskIn, d, -1, count_jbf, weight_o,sigma_d,...
            winsz,thres,weight_s,rect,y);            
        if g_t <= g_thres
            disp(['frame ',int2str(id), '------------total for ', int2str(count_jbf), ' times!']);
            break;
        end
        disp(['g_t = ',int2str(g_t), ', now is ' ,int2str(count_jbf), 'th circle time']);
        fprintf('depth resolution = %d*%d',size(maskIn,1),size(maskIn,2));
        count_jbf = count_jbf + 1;    
    end
    maskOut = maskIn;
end
    