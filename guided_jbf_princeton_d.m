function [mask_gbf, weight_o, g_t, weight_s]= guided_jbf_princeton_d(mask, I, is_ime, count_i, weight, ...
    sigma, win_width, thres, weight_sum, rectIn,y)
    
    global debug_mode;
    I = double(I);
    [H, W]  =size(mask);  
%     mask_gbf = zeros(H,W);
    mask_gbf = mask;%Jacobi

    num_win = win_width*win_width;
    half_w = (win_width-1)/2;
    g_t = 0;                       %count the num of changing pixels in mask
    sigma_precompute = -2*sigma*sigma;
    r_start = half_w+1;            % round((win_height + 1)/2);  
    r_end = round(H - half_w-1);
    c_start = half_w+1;     c_end = round(W - half_w-1);
    
    G1_mat = fspecial('gaussian', win_width, half_w);
    fprintf('win_width=%d,half_w=%d\n',win_width,half_w);
    G1_vec = G1_mat;
    win_vec = -half_w:half_w;

    weight_o = zeros([win_width, win_width, H*W]);
    weight_s = zeros([1,H*W]); %weight_sum
    
    %%only for count weight_o
    if count_i == 0 %
        t = zeros(1, H*W);
        for r = r_start : r_end
            for c = c_start : c_end          
                if r < rectIn(2) || r > rectIn(2)+rectIn(4) || c < rectIn(1) || c > rectIn(1)+rectIn(3), continue; end
                tic;
                vec_patch = I(r+win_vec, c+win_vec);
                vec_i = ones(win_width, win_width)*I(r,c);
                weight_vec = exp((vec_i - vec_patch).^2/sigma_precompute).*G1_vec;
                weight_o(:,:,(r-1)*W+c) = weight_vec;
                weight_s(:,(r-1)*W+c) = sum(sum(weight_o(:,:,(r-1)*W+c)));
                t(1,(r-1)*W+c) = toc;
            end
        end 
        disp(['Time of computing weight = ', num2str(sum(t))]);
        disp(['computing depth weight time per pixel:',num2str(sum(t)/(rectIn(3)*rectIn(4)))]);
        return;
    end
    

%     t = zeros(6,H*W); 
    tic;
    for r = r_start : r_end
        for c = c_start : c_end  
            if r < rectIn(2) || r > rectIn(2)+rectIn(4) || c < rectIn(1) || c > rectIn(1)+rectIn(3), continue; end
%             tic; mask_vec = mask_gbf(r+win_vec, c+win_vec); t(1,(r-1)*W+c) = toc;
%             tic; if ~mask_vec, mask_gbf(r,c) = 0; continue; end; t(2,(r-1)*W+c) = toc;
%             tic; if sum(sum(mask_vec))==num_win, mask_gbf(r,c) = 1; continue; end; t(3,(r-1)*W+c) = toc;
%             tic; weight_vec = weight(:,:,(r-1)*W+c); t(4,(r-1)*W+c) = toc;
%             tic; 
%             res_i = sum(sum(weight_vec.*mask_vec))/weight_sum((r-1)*W+c); 
%             t(5,(r-1)*W+c) = toc;
%             tic; mask_gbf(r,c) = res_i>thres; t(6,(r-1)*W+c) = toc;    

            mask_vec = mask_gbf(r+win_vec, c+win_vec);
            if ~mask_vec, mask_gbf(r,c) = 0; continue; end
            if sum(sum(mask_vec))==num_win, mask_gbf(r,c) = 1; continue; end
            weight_vec = weight(:,:,(r-1)*W+c);
            
            res_i = sum(sum(weight_vec.*mask_vec))/weight_sum((r-1)*W+c); 
            mask_gbf(r,c) = res_i>thres;
        end
    end 
%     disp(['t1 = ',num2str(sum(t(1,:)))]);
%     disp(['t2 = ',num2str(sum(t(2,:)))]);
%     disp(['t3 = ',num2str(sum(t(3,:)))]);
%     disp(['t4 = ',num2str(sum(t(4,:)))]);
%     disp(['t5 = ',num2str(sum(t(5,:)))]);
%     disp(['t6 = ',num2str(sum(t(6,:)))]);
    t = toc;
    disp(['depth sum time = ',num2str(t)]);
    disp(['depth per pixel time = ',num2str(t/(rectIn(3)*rectIn(4)))]);

    
if debug_mode
    Res_I(:,:,1) = mask_gbf*255;
    Res_I(:,:,2) = y(:,:,1);
    Res_I(:,:,3) = zeros(H,W);

    figure(4), imshow(uint8(Res_I)), title('after JBF'),drawnow;
    Res_I(:,:,1) = mask*255;
    figure(3), imshow(uint8(Res_I)), title('before JBF'),drawnow;
end
g_t = abs(sum(sum(logical(mask) - logical(mask_gbf))));
end
