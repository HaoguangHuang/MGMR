function drawIOU
    
%     dir_name = 'output_20180228_2226';
    dir_name = 'output_20180209_1110';
    series_mat = {'zcup_move_1','child_no1','tracking4','toy_wg_occ','dog_no_1'};
    objectBased_mean_avg = [64.07,54.34,56.22,86.45,48.81];
    MWC = [31.22,28.66,33.94,56.87,35.44];
    TVA = [49.87,61.61,54.82,61.23,19.86];
    pixel_trslation = 2:2:30;
    
    pt_num = length(pixel_trslation);
    s_num = length(series_mat);
    IOU_table = zeros(s_num,pt_num);
    for s = 1:s_num 
        series = series_mat{s};
        for p = 1:pt_num
            tmp = {};
            IOU_fname = sprintf('./hhg_algorithm/%s/%s/pt_%d/IOU_res.txt',dir_name,series,2*p-2);
            fid = fopen(IOU_fname,'r');
            if fid<0, fprintf('open file %s failed!',IOU_fname); continue; end
            while 1
                tline = fgetl(fid);
                if ~ischar(tline), break; end
                tmp = [tmp; tline];
            end
            str = tmp{end-1}; 
            iou = sscanf(str,'IOU avg:%s');
            iou = str2double(iou);
            IOU_table(s,p) = iou;
            fclose(fid);
        end
    end
    IOU_table(end+1,:) = mean(IOU_table);
    %------draw
%     for s = 1:s_num
%         figure(s+6);
%         plot(pixel_trslation,IOU_table(s,:));
%         xlabel('pixel translation');ylabel('IOU');
%         title(sprintf('IOU of %s',series_mat{s}));
%         grid on;
%     end

%     close figure 6
    figure(length(series_mat)+2);
    plot(pixel_trslation,IOU_table(end,:));hold on;
    plot(pixel_trslation,mean(objectBased_mean_avg)*ones(size(pixel_trslation)),'r-');
%     plot(pixel_trslation,mean(MWC)*ones(size(pixel_trslation)),'g.--');
    plot(pixel_trslation,mean(TVA)*ones(size(pixel_trslation)),'k--');
    axis([2,30,45,80]);
    hold off;
    legend('MGMR','Object-based','TVA');
    xlabel('Distance (pixel)');ylabel('IOU (%)');
%     title('IOU of avg');
    grid on;
end