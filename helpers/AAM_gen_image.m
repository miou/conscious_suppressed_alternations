function  [im, landmark]= AAM_gen_image( p_id_mark, p_id_texture, model, output_res )
% AAM_gen_image
%

% buffer size
resx = output_res(2)*model.image.upsampling; 
resy = output_res(1)*model.image.upsampling;


%% mark
nmark = length(p_id_mark);
neutral_mark = model.id_mark.mean' + model.id_mark.eig_vector(:,1:nmark) * p_id_mark;
neutral_mark = reshape(neutral_mark, [], 2);

% scale face area to proportion of images
peri_ind = [model.mark_group.rim model.mark_group.rim(1)];
area = polyarea(neutral_mark(peri_ind,1), neutral_mark(peri_ind,2));
scaling_factor = sqrt(resx * resy * 0.6 / area);

dy = model.image.y_offset_factor * resx;

neutral_mark(:,1) = neutral_mark(:,1) * scaling_factor + resx/2;
neutral_mark(:,2) = neutral_mark(:,2) * scaling_factor + resy/2 + dy;

%% texture
ntexture = length(p_id_texture);
[resy_texture, resx_texture] = size(model.x_texture);
neutral_texture = model.id_texture.mean' + model.id_texture.eig_vector(:,1:ntexture) * p_id_texture ;
neutral_texture = reshape(neutral_texture, resy_texture, resx_texture, 3);

[im, mask] = draw_texture( neutral_texture, model.id_mark.mean, model.x_texture, model.y_texture, neutral_mark, resx, resy, model.facets );

%% smooth edge
if model.image.smooth_edge
    sigma = model.image.smooth_factor*resx;
    im = im_mask_smooth_edge(im, mask, sigma);
end

%%
if model.image.upsampling>1
    im = imresize(im, output_res);
end

landmark = neutral_mark;
end

