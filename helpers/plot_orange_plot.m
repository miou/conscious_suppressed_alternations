function orange_image = plot_orange_plot(orange_matrix)
if ~isempty(orange_matrix)
    % orange_image = imagesc(1:size(orange_matrix,2),1:size(orange_matrix,1),orange_matrix,[-max(max(orange_matrix)),max(max(orange_matrix))]);
    orange_image = imagesc(1:size(orange_matrix,2),1:size(orange_matrix,1),orange_matrix,[-1,1]);
else
    orange_image = [];
end
set(gca,'YDir','normal')
orangemap = esa(300);
[white_color, white_pos] = max(sum(orangemap,2));

orangemap = orangemap([1:white_pos round(linspace(white_pos+1,size(orangemap,1)-2,white_pos-1))],:);
colormap(orangemap)
xticks(1:16:size(orange_matrix,2))
yticks([1 10:10:size(orange_matrix,1)]);
