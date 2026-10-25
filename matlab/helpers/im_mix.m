function im = im_mix(im1, im2, alpha, sigma)
% im_mix(im1, im2, alpha, sigma)
% mix image1 and image2 according to alpha channel
% INPUT: im1, im2, images of same resolution
%             alpha, matrix specify weights of the mix for each pixel
%             sigma: smooth alpha to avoid sharp edge, sigma of Gaussian smooth in pixel

im1 = double(im1);
im2 = double(im2);
alpha = double(alpha);

if nargin<4
    sigma = 0;
end

if sigma >0
    alpha = imgaussfilt(alpha, sigma);
end

part1 = bsxfun(@times, im1, alpha); 
part2 = bsxfun(@times, im2, 1-alpha);
im = bsxfun(@plus, part1, part2);

