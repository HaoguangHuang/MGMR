function maskOut = color_jbf(y,id,maskIn,rect,thres,winsz,sigma_c)
    count_jbf = 0;%第一次执行
    weight_i = zeros(1,1);
    [~, weight_o,~,weight_s]= guided_jbf_princeton_c(maskIn,y,-1,count_jbf,weight_i,sigma_c,winsz,thres,0,rect);%这里只是计算了weight_o
    count_jbf = count_jbf + 1;
    g_thres = 10;%guided thres------per pixel
    g_t = inf;
    
    while 1
        [maskIn, ~, g_t,~] = guided_jbf_princeton_c(maskIn,y,-1,count_jbf,weight_o,sigma_c,winsz,thres,weight_s,rect);
        if g_t <= g_thres
            disp(['frame ',int2str(id), '------------total for ', int2str(count_jbf), ' times!']);
            break;
        end
        count_jbf = count_jbf + 1;
        disp(['g_t = ',int2str(g_t), ', now is ' ,int2str(count_jbf), 'th time']);
        fprintf('color resolution = %d*%d\n',size(maskIn,1),size(maskIn,2));
    end
    maskOut = maskIn;
end