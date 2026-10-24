 function v=shuffle_array(v,dim)
 if nargin==1 || isempty(dim)
     v=v(randperm(length(v)));
 elseif dim == 1
     v=v(randperm(size(v,1)),:);
     
 elseif dim == 2
     v=v(:,randperm(size(v,2)));
 end
 end
