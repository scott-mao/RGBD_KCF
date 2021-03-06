function feature_map = get_deep_features(im, fparams)
    % Get layers from a cnn.
    if size(im,3) == 1
        im = repmat(im, [1 1 3]);
    end

    im_sample_size = size(im);
    
    %preprocess the image
    if ~isequal(im_sample_size(1:2), fparams.net.meta.normalization.imageSize(1:2))
        im = imresize(single(im), fparams.net.meta.normalization.imageSize(1:2));
    else
        im = single(im);
    end

    % Normalize with average image
    im = bsxfun(@minus, im, fparams.net.meta.normalization.averageImage);

    if fparams.use_gpu
        im = gpuArray(im);
        cnn_feat = vl_simplenn(fparams.net, im,[],[],'CuDNN',true, 'Mode', 'test');
    else
        cnn_feat = vl_simplenn(fparams.net, im, [], [], 'Mode', 'test');
    end

    feature_map = cell(1,1,length(fparams.output_layer));

    for k = 1:length(fparams.output_layer)
        if fparams.downsample_factor(k) == 1
%             feature_map{k} = cnn_feat(fparams.output_layer(k) + 1).x(fparams.start_ind(k,1):fparams.end_ind(k,1), fparams.start_ind(k,2):fparams.end_ind(k,2), :, :);
        feature_map{k} = cnn_feat(fparams.output_layer(k) + 1).x;
        else
%             feature_map{k} = vl_nnpool(cnn_feat(fparams.output_layer(k) + 1).x(fparams.start_ind(k,1):fparams.end_ind(k,1), fparams.start_ind(k,2):fparams.end_ind(k,2), :, :), fparams.downsample_factor(k), 'stride', fparams.downsample_factor(k), 'method', 'avg');
        feature_map{k} = vl_nnpool(cnn_feat(fparams.output_layer(k) + 1).x, fparams.downsample_factor(k), 'stride', fparams.downsample_factor(k), 'method', 'avg');
        end
    end
    
    % Do feature normalization
    feature_map = cellfun(@(x) bsxfun(@times, x, ...
                sqrt((size(x,1)*size(x,2))^fparams.normalize_size * size(x,3)^fparams.normalize_dim ./ ...
                (sum(reshape(x, [], 1, 1, size(x,4)).^2, 1) + eps))), ...
                feature_map, 'uniformoutput', false);
 
end