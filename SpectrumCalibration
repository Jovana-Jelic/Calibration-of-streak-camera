% Kalibracija_spektara.m

%% Initialization
clc;        % Clear command window
clear;      % Clear workspace
close all;  % Close all figures

%% Settings
filename = 'spektar lampe_Rho110.txt';  % Your .txt file
delimiter = ';';        % Delimiter
headerLines = 88;       % Number of lines to skip as header
decimalSeparator = ','; % Decimal is comma 

%% 📖 Reading data
fileID = fopen(filename, 'r', 'n', 'UTF-8');
textData = textscan(fileID, '%s', 'Delimiter', '\n');
textData = textData{1};
fclose(fileID);

% Skip header
textData = textData(headerLines+1:end);

% Extract column names (from 89th line)
columnNamesLine = textData{1};
columnNames = strsplit(columnNamesLine, delimiter);

% Read actual data (from 90th line onward)
dataLines = textData(2:end);

%% ⚙️ Processing data
numCols = length(columnNames);
numRows = length(dataLines);
dataMatrix = NaN(numRows, numCols);

for i = 1:numRows
    line = strrep(dataLines{i}, decimalSeparator, '.'); % Replace ',' with '.'
    elements = strsplit(line, delimiter);
    if length(elements) == numCols
        dataMatrix(i, :) = str2double(elements);
    end
end

% Extract Wavelength (2nd column) and Dark Subtracted (8th column)
wavelength = dataMatrix(:,2);
intensity_BGcorrected = dataMatrix(:,8);

%% Wavelength calibration 
WavelengthCal = 0.99508 * wavelength + 3.95406; % Coefficients obtained on the basis of our calibration 

%% Intensity calibration

SensitivityCurve = 'Kriva osetljivosti.txt';
delimiter = ' ';        % Delimiter used in the file
decimalSeparator = '.'; % Decimal is period 

%% 📖 Reading the sensitivity curve file
fileID = fopen(SensitivityCurve, 'r');
sensitivityData = textscan(fileID, '%f %f', 'Delimiter', ' ', 'CollectOutput', true);
fclose(fileID);
sensitivityData = sensitivityData{1};  % Extract the numeric matrix

% Assign columns
wavelength_sensitivity = sensitivityData(:,1);
sensitivity = sensitivityData(:,2);

%% Calibrated Intensity Calculation
CalibratedIntensity = intensity_BGcorrected ./ sensitivity;

%% 📊 Plotting spectra
figure;
plot(WavelengthCal, CalibratedIntensity, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Calibrated Spectrum');
xlabel('Wavelength (nm)');
ylabel('Intensity (a.u.)');
title('Calibrated Spectra');
legend('show'); 
grid on;

%% 💾 Saving and Displaying results
[~, baseName, ~] = fileparts(filename);  % Extract base name from input file
outputFile = [baseName '_calibrated_spectrum.txt'];

fileID = fopen(outputFile, 'w');
fprintf(fileID, 'Wavelength (nm)\tCalibrated Intensity (a.u.)\n');  % Header
for i = 1:length(WavelengthCal)
    fprintf(fileID, '%.6f\t%.6f\n', WavelengthCal(i), CalibratedIntensity(i));
end
fclose(fileID);

disp(['Spectrum saved as ' outputFile]);


hold off;
