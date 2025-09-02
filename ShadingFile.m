%% Initialization
clc;
clear;
close all;

%% PARAMETERS
spectrumFile = 'Lampspectrum.txt';         % Spectrum text file: wavelength | intensity (640 points)
referenceImageFile = 'Lamp.img';  % Lamp .img file to copy header from
outputImageFile = 'ShadingFile.img';       % Output file
imageWidth = 640;
imageHeight = 480;
scaleMax = 32000;  % Final scaling maximum value

%% Load original binary image to copy header
fid = fopen(referenceImageFile, 'r');
if fid == -1
    error('Cannot open file: %s', referenceImageFile);
end
A = fread(fid, 'uint16=>uint16');
fclose(fid);

%% Compute image data start index
start = int32((A(2) + 64) / 2 + 1);

%% Extract and reshape image
image1D = A(start : start + imageWidth * imageHeight - 1);
imageMatrix = reshape(double(image1D), [imageWidth, imageHeight])';  % Ensure double precision

%% === STEP 1: Multiply image by 1000 ===
imageMultiplied = imageMatrix * 1000;

%% === STEP 2: Smooth the image ===
smoothedImage = imgaussfilt(imageMultiplied, 10);  % Sigma = 25

%% === STEP 3: Load and scale intensity data ===
data = load(spectrumFile);         % Load the text file (2 columns: wavelength, intensity)
intensity = data(:, 2);            % Use only the intensity values (second column)

% Validate the number of values
if length(intensity) ~= imageWidth
    error('Spectrum must contain exactly %d intensity values.', imageWidth);
end

% Find min and max
minVal = min(intensity);
maxVal = max(intensity);

fprintf('Original min: %.6f\n', minVal);
fprintf('Original max: %.6f\n', maxVal);

% Normalize: max becomes 1, min becomes min/max


normalizedIntensity = intensity / maxVal;  % Ensure normalization is done in double precision

% Scale to [0, 32000]
scaledIntensity = normalizedIntensity * scaleMax;  % Ensure scaling in double precision

%% === STEP 4: Generate image matrix ===
% Repeat the scaled intensity row 480 times to make a 480x640 image
GeneratedImageMatrix = repmat(scaledIntensity', imageHeight, 1);   % Transpose first to row

%% === STEP 5: Perform shading correction ===
% Check the range of the smoothed image and GeneratedImageMatrix before division
disp(['Range of smoothedImage: ', num2str(min(smoothedImage(:))), ' to ', num2str(max(smoothedImage(:)))]);
disp(['Range of GeneratedImageMatrix: ', num2str(min(GeneratedImageMatrix(:))), ' to ', num2str(max(GeneratedImageMatrix(:)))]);

% Perform division with check for zeros in GeneratedImageMatrix
ShadingImageRaw = 32000 * (smoothedImage ./ GeneratedImageMatrix);
ShadingImage = 1000 * (ShadingImageRaw / max(ShadingImageRaw(:)));
% Check the range of ShadingImage after division
disp(['Range of ShadingImage (before clipping): ', num2str(min(ShadingImage(:))), ' to ', num2str(max(ShadingImage(:)))]);


%% === STEP 6: Save visual PNG previews of Generated and Shading images ===

% --- Save generated image (from spectrum) ---
figure('Visible', 'off');
imshow(GeneratedImageMatrix, []);
colormap(jet);
colorbar;
title('Generated Image from Spectrum');
saveas(gcf, 'GeneratedImage_jet.png');

% --- Save final shading image (after division) ---
figure('Visible', 'off');
imshow(ShadingImage, []);
colormap(jet);
colorbar;
title('Shading Correction Map');
saveas(gcf, 'ShadingImage_jet.png');

%% === STEP 7: Flatten and insert corrected image into buffer ===
imageFlat = reshape(uint16(ShadingImage)', [], 1);  % Column-major order
A(start : start + numel(imageFlat) - 1) = imageFlat;



%% === STEP 8: Save final image ===
fid = fopen(outputImageFile, 'w');
if fid == -1
    error('Cannot open output file: %s', outputImageFile);
end

fwrite(fid, A, 'uint16');
fclose(fid);

disp(['✅ Shading-correction image saved to "' outputImageFile '".']);

