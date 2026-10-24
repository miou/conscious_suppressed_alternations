function [ im ] = im_mask_smooth_edge( im, mask, sigma)
% make smooth transition along mask edge
% to gray background 
% INPUT: 
%     im: image
%     mask: binary array as same size of image 
%                or polygon defined by sequence of points (n, 2)
%     sigma: sigma of Gaussian smooth in pixel
%

[y, x] = size(im(:,:,1));

if nargin<3
    sigma = y*0.005;
end

bg = 128;

if ~islogical(mask)
    % if it's not bool, it should be a polygon.
    [xx, yy] = meshgrid(1:x,1:y);
    in  = inpolygon(xx(:), yy(:), mask(:,1), mask(:,2));
    mask = reshape(in, y, x);
end

mask = double(mask);
mask = imgaussfilt(mask, sigma);

mask = (mask - 0.5)*2;
mask(mask<0 ) = 0;

% figure; imagesc(mask)
im = im_mix(im, bg, mask);

