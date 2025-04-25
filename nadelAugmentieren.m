function nadelAugmentieren
% Expands training data by augmenting

clc;
fprintf('Augmenting data ...\n');

% Search for all images for training and create a datastore
folder = fullfile('MESS\training_data_pics');
imds = imageDatastore(folder, 'IncludeSubfolders',true,...
    'FileExtensions','.png', 'LabelSource','none');

% Number of training data without augmentation
count = numel(imds.Files);
fprintf(['Images found in the training folder: ', num2str(count),'\n']);
if count < 1
    fprintf('No images found! Aborting.\n');
    return;
end

% Folder for new images
aug_folder = fullfile('MESS\training_data_pics','NadelAugData');
if ~exist(aug_folder,'dir')
    mkdir(aug_folder);
end

images_per_aug = 3; % 3 augmented images per original
i_original = 0;
i_aug = 0;

reset(imds); 
% Iterate through all images
while hasdata(imds)
    % Load image and image information from datastore
    [original, infos] = read(imds);
    [~, FileName, FileExtension] = fileparts(infos.Filename);

    % Check if augmented versions already exist for this image
    finished_aug = dir(fullfile(aug_folder, [FileName,'_aug*', FileExtension]));
    num_finished_aug  = numel(finished_aug);
    if num_finished_aug >= images_per_aug
        i_original = i_original + 1;
        continue;
    end

    % If more augmented images are needed, generate them
    for a = (num_finished_aug + 1) : images_per_aug
        aug_Image = random_augmentation(original);
        aug_Name = sprintf('%s_aug%d%s', FileName, a, FileExtension);
        % => Example: "nadelFrame00001_35.20_aug1.png"
        imwrite(aug_Image, fullfile(aug_folder, aug_Name));
        i_aug = i_aug + 1;
    end

    i_original = i_original + 1;
    % Calculate and display progress
    percent = (i_original / count) * 100;
    fprintf('Original: %d/%d (%.1f%%)\n', i_original, count, percent);
end

fprintf('Done augmenting!\n');
fprintf(['Generated augmented images: ', num2str(i_aug),'\n']);
end


function aug_Image = random_augmentation(inputImage)
% Generates a single augmented image:

% 1) Random rotation +/-15°
angle = randi([-15,15],1);
aug_Image = imrotate(inputImage, angle, 'bicubic', 'crop');

% 2) Randomly flip along different axes
if rand < 0.5
    aug_Image = flip(aug_Image, 2);
end
if rand < 0.3
    aug_Image = flip(aug_Image, 1);
end

% 3) Randomly scale between 0.9 and 1.1
scale = 0.9 + 0.2 * rand;
aug_Image = imresize(aug_Image, scale);
[H, W, ~] = size(aug_Image);

if H < 224 || W < 224 % Image too small, pad sides
    padH = 224 - H; padW = 224 - W;
    t = floor(padH / 2);
    l = floor(padW / 2);
    aug_Image = padarray(aug_Image, [t l], 'replicate', 'pre'); 
    aug_Image = padarray(aug_Image, [padH - t, padW - l], 'replicate', 'post'); 
else % Image too large, crop sides
    first_row = floor((H - 224) / 2) + 1;
    first_col = floor((W - 224) / 2) + 1;
    aug_Image = imcrop(aug_Image, [first_col first_row 223 223]);
end

% 4) Random brightness adjustment +/-10%
aug_Image = im2double(aug_Image);
brightness = 1 + 0.2 * (rand - 0.5);
aug_Image = aug_Image * brightness;
aug_Image = mat2gray(aug_Image);
% Image with 0 to 255 grayscale
aug_Image = im2uint8(aug_Image);
end
