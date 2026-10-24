function aft = affine_transform_triangles( vs, vt, facets )
%AFFINE_TRANSFORM_TRIANGLES 
% vs: vertices source
% vt: vertices target
% facets: index of facets
% by Liang, 2016.6

vs(:,3) = 1;
vt(:,3) = 1;

n = size(facets,1);
aft = zeros(3,3,n);
for i = 1:n
    fi = facets(i,:);
    aft(:,:,i) = vt(fi,:)' / (vs(fi,:)');
end



end

