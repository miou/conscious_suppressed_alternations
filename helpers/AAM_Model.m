classdef AAM_Model
    % AAM_MODEL Active Apearance Model
    %
    
    properties
        data
        npc_mark % number of PC
        npc_texture
    end
    
    methods
        
        %% constructor
        function self = AAM_Model(data_file)
            load(fullfile(data_file))
            self.data = model;
            self.npc_mark = npc_id_mark;
            self.npc_texture = npc_id_texture;
        end
        
        %% helper
        function examination(self, output_path, output_res)
            if nargin<3
                Model_examination(self.data, output_path)
            else
                Model_examination(self.data, output_path, output_res)
            end
        end
        
        function params = gen_random_params(self, n, seed)
            % generate random paramters
            % n: number of samples to generate
            p_id_mark = gen_randn_param( n, self.data.id_mark, seed);
            p_id_texture = gen_randn_param( n, self.data.id_texture, seed);
            params = [p_id_mark' p_id_texture'];
        end
        
        function params = gen_fixed_params(self, nface, std_values)
            % generate fixed paramters
            % n: number of samples to generate
            p_id_mark = gen_fixed_param( nface, self.data.id_mark, std_values(1:self.npc_mark,:));
            p_id_texture = gen_fixed_param( nface, self.data.id_texture, std_values(self.npc_mark+1:end,:));
            params = [p_id_mark' p_id_texture'];
        end


        %% compute_param
        % image and marks to params in PCA space
        function param = compute_param(self, im_data, marks_raw)
            
            ndim = self.npc_mark + self.npc_texture;
            n_faces = length(im_data);
            param = zeros(n_faces, ndim);
            
            for i = 1:n_faces
                
                %fprintf('%d/%d\n', i, n_faces)
                marks = marks_raw(:,:,i);
                im = im_data{i};
                
                resy = size(im,1);
                resx = size(im,2);
                
                texture_template = draw_texture( im, marks, resx, resy, ...
                    self.data.id_mark.mean, self.data.x_texture, self.data.y_texture, self.data.facets );
                
                marks_norm = mark_normalize(marks);
                p_id_mark = self.data.id_mark.eig_vector' * (marks_norm(:) - self.data.id_mark.mean');
                p_id_texture = self.data.id_texture.eig_vector' * (texture_template(:) - self.data.id_texture.mean');
                
                param(i,:) = [p_id_mark' p_id_texture'];
            end
            
        end
        
        %% gen_image_param ()
        % generate image from provided parameters
        function [im_syn, landmarks] = gen_image_param(self, params, output_res, options)
            % [im_syn, landmarks] = gen_image_param(self, params, output_res, options)
            % INPUT:
            %    params: shape-appearance paramters 
            %    output_res: output resolution
            % 
            %    [optional] 
            %        options.ndim_shape: number of shape dimension
            %        options.normalized: true or false, params is normalized or not
            
            if nargin<4
                options = [];
            end
            
            if isfield(options, 'ndim_shape')
                nmark = options.ndim_shape;
            else
                nmark = self.npc_mark;
            end
            
            ntexture = size(params,2) - nmark; 
            
            % if params are normalized, recover its scale
            if isfield(options, 'normalized') && options.normalized
                p_std = [self.data.id_mark.score_std(1:nmark) self.data.id_texture.score_std(1:ntexture) ];
                p_mean = [self.data.id_mark.score_mean(1:nmark) self.data.id_texture.score_mean(1:ntexture) ];
                params = bsxfun(@times, params, p_std);
                params = bsxfun(@plus, params, p_mean);
            end
            
            n = size(params,1);
            im_syn = zeros([output_res, 3, n]);
            landmarks = zeros(length(self.data.id_mark.mean)/2,2,n);
            
            params_id_mark = params(:,1:nmark);
            params_id_texture = params(:, nmark+1:end);
            for index = 1:n
                %fprintf('Generating images %d/%d\n',i,n);
                p_id_mark = params_id_mark(index,:)';
                p_id_texture = params_id_texture(index,:)';
                [im_syn(:,:,:,index), landmarks(:,:,index)]= AAM_gen_image( p_id_mark, p_id_texture, self.data, output_res);
            end
        end
        
        %% gen_image_internal(index, output_res)
        % index: index of internal images/ training images
        function im_syn = gen_image_internal(self, index, output_res)
            
            if ~isfield(self.data.id_mark, 'score')
                im_syn = [];
                return
            end
            
            n = length(index);
            im_syn = zeros([output_res, 3, n]);
            for i = 1:n
                p_id_mark = self.data.id_mark.score(index(i),:)';
                p_id_texture = self.data.id_texture.score(index(i),:)';
                im_syn(:,:,:,i) = AAM_gen_image( p_id_mark, p_id_texture, self.data, output_res);
            end

        end
        
    end
    
end
    
