function [im, pt_ind_all] = draw_texture( source_texture, source_mark, source_x, source_y, target_mark, target_x, target_y, facets )
%DRAW_TEXTURE
% example 


%% input check
if size(source_mark,2)~=2
    source_mark = reshape(source_mark,[],2);
end

if size(target_mark,2)~=2
    target_mark = reshape(target_mark,[],2);
end

if isinteger(source_texture)
    source_texture = single(source_texture);
end

%%
[sx, sy] = xy2grid(source_x, source_y);
[tx, ty] = xy2grid(target_x, target_y);

% compute affine transformation
aft = affine_transform_triangles(target_mark, source_mark, facets);

xt = nan(size(tx)); % target x transformed in source coordinate
yt = nan(size(ty));

%%
nf = size(facets,1);
for i = 1:nf
    xv = target_mark(facets(i,:),1);
    yv = target_mark(facets(i,:),2);
    pt_ind = inpolygon(tx(:), ty(:), xv, yv); % locate points belong to each facets in target image
    xyt = [tx(pt_ind) ty(pt_ind) ones(sum(pt_ind),1)] * aft(:,:,i)';  %  piece-wise transform
    xt(pt_ind) = xyt(:,1);
    yt(pt_ind) = xyt(:,2);
end

%%
nch = size(source_texture,3);
[target_resy, target_resx] = size(tx);

im = nan(target_resy, target_resx, nch);

% fill image
pt_ind_all = ~isnan(xt);
for i = 1:nch
    im1 = nan(target_resy, target_resx);
    im1(pt_ind_all) = interp2(sx, sy, source_texture(:,:,i), xt(pt_ind_all), yt(pt_ind_all));
    im(:,:,i) = im1;
end

ind = ~isnan(im);
im(~ind) = 128;

% adjust contrast
% im_max = max(im(ind(:)));
% im_min = min(im(ind(:)));
% im = (im - im_min)/(im_max-im_min) * 255;


end

function [x_grid, y_grid] = xy2grid(x, y)

if isscalar(x)
    [x_grid, y_grid] = meshgrid(1:x, 1:y);
    
elseif size(squeeze(x),2)==1
    % if source coordinate is one dimension
    [x_grid, y_grid] = meshgrid(x, y);
    
else
    x_grid = x;
    y_grid = y;
end

end
