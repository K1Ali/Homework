export = readtable('C:\Users\Ali Kazimov\Downloads\586a2b27-1dc6-4470-8009-daab61d37806.xls');
GDP = readtable('C:\Users\Ali Kazimov\Downloads\DP_LIVE_05092023005745140.csv');
dist = readtable('C:\Users\Ali Kazimov\Downloads\dist_cepii.xls');
%Export data was taken from https://www.oecd-ilibrary.org/trade/data/oecd-quarterly-international-trade-statistics_qits-data-en
%It is called: Trade in value by partner countries. I did some customizing (as choosing only 2022 annual data etc.) on site
%before downloading it.
%GDP ==> (again some changes before downloading) https://data.oecd.org/gdp/gross-domestic-product-gdp.htm#indicator-chart
%dist ==> http://www.cepii.fr/CEPII/en/bdd_modele/bdd_modele_item.asp?id=6
firstColumn = export.ReporterCountry;
export.Var2 = [];
export(45,:) = [];
x = export.Properties.VariableNames;
MAIN = dist(ismember(dist.iso_o, x), :);
MAIN = MAIN(ismember(MAIN.iso_d, firstColumn), :);
MAIN = MAIN(:, [1,2,11]);
for i = 1:size(MAIN, 1)
    matchIdx = strcmp(MAIN.iso_o{i}, GDP.LOCATION);
    if any(matchIdx)
        MAIN.GDP(i) = GDP.Value(matchIdx);
    end
end
MAIN(MAIN.GDP == 0, :) = [];
MAIN.export = NaN(size(MAIN, 1), 1);
for i = 1:size(MAIN, 1)
    matchIdx = strcmp(export.ReporterCountry, MAIN.iso_d{i});
    if any(matchIdx)
        varName = MAIN.iso_o{i};
        if ismember(varName, export.Properties.VariableNames)
            MAIN.export(i) = export{matchIdx, varName};
        end
    end
end
for i = 1:size(MAIN, 1)
    matchIdx = strcmp(MAIN.iso_d{i}, GDP.LOCATION);
    if any(matchIdx)
        MAIN.GDP_j(i) = GDP.Value(matchIdx);
    end
end
MAIN(MAIN.GDP_j == 0, :) = [];
import = readtable('C:\Users\Ali Kazimov\Downloads\d0a28323-4eec-44a4-80c8-f93e822a109f.xls','Sheet',2);
for i = 1:size(MAIN, 1)
    matchingRows = strcmp(import.ReporterCountry, MAIN.iso_o{i}) & strcmp(import.ReporterCountry, MAIN.iso_d{i});
    
    if any(matchingRows)
        MAIN.export(i) = import.DomesticTrade(matchingRows);
    end
end
unique_values = unique(MAIN.iso_d);
unique_values1 = unique(MAIN.iso_o);
common_values = intersect(unique_values, unique_values1);
logical_index = ismember(MAIN.iso_o, common_values);
MAIN = MAIN(logical_index, :);
logical_index = ismember(MAIN.iso_d, common_values);
MAIN = MAIN(logical_index, :);

cellArray = table2cell(MAIN);
numColumns = size(cellArray, 2);
columnVectors = cell(1, numColumns);
for col = 1:numColumns
    columnVectors{col} = cellArray(:, col);
end
dist = cell2mat(columnVectors{3});
GDP.GDP = GDP.Value;
logical_index = ismember(GDP.LOCATION, common_values);
GDP = GDP(logical_index, :);
GDP = GDP(:, "GDP");
dist = reshape(dist,[],28);
export = cell2mat(columnVectors{5});
export = reshape(export,[],28)';
modifiedNames = strcat(common_values, '_dist');
dist = array2table(dist, 'VariableNames', modifiedNames);
dist.Properties.RowNames = common_values;
modifiedNames = strcat(common_values, '_export');
export = array2table(export, 'VariableNames', modifiedNames);
export.Properties.RowNames = common_values;
gravity = [dist, GDP, export];
%clearvars -except gravity
%%
GDP_i = log(table2array(GDP));
GDP_j = GDP_i';
GDP_i = repmat(GDP_i, 1, 28);
GDP_j = repmat(GDP_j, 28, 1);
GDP_j = reshape(GDP_j, [], 1);
GDP_i = reshape(GDP_i, [], 1);
dist_ij = log(table2array(dist));
dist_ij = reshape(dist_ij, [], 1);
export_ij = log(table2array(export));
export_ij = reshape(export_ij, [], 1);
b = fitlm([GDP_i,GDP_j, dist_ij], export_ij, "linear");
%%
contig = readtable('C:\Users\Ali Kazimov\Downloads\dist_cepii.xls');
x = export.Properties.RowNames;
contig = contig(ismember(contig.iso_o, x), :);
contig = contig(ismember(contig.iso_d, x), :);
contig(:,4:end)=[];

source_countries = unique(contig.iso_o);

dummy_variables = zeros(length(contig.iso_o), length(source_countries) - 1);

for i = 1:length(source_countries)
    if i < length(source_countries)
        dummy_variables(:, i) = strcmp(contig.iso_o, source_countries{i});
    end
end
dummy_variable_names = strcat('dummy_', source_countries(1:end-1));

data_with_dummies = [contig array2table(dummy_variables, 'VariableNames', dummy_variable_names)];
destination_countries = unique(contig.iso_d);

dummy_variables = zeros(length(contig.iso_d), length(destination_countries) - 1);

for i = 1:length(destination_countries)
    if i < length(destination_countries)
        dummy_variables(:, i) = strcmp(contig.iso_d, destination_countries{i});
    end
end
dummy_variable_names = strcat('dummy_2_', destination_countries(1:end-1));

data_with_dummies_2 = [contig array2table(dummy_variables, 'VariableNames', dummy_variable_names)];
gdp = table2array(GDP);
sumValue = sum(gdp(1:28, 1));
sumValue = log(sumValue);
SumGdp = repmat(sumValue, 1, 784)';
border = contig(:,"contig");

subsetTable = data_with_dummies(:, 4:30);
subsetTable_2 = data_with_dummies_2(:, 4:30);

dataMatrix = table2array(subsetTable);
numColumns = size(dataMatrix, 2);

for i = 1:numColumns
    eval(['origin_', char(source_countries(i)) , ' = dataMatrix(:, ', num2str(i), ');']);
end
dataMatrix = table2array(subsetTable_2);
numColumns = size(dataMatrix, 2);
for i = 1:numColumns
    eval(['destination_', char(destination_countries(i)) , ' = dataMatrix(:, ', num2str(i), ');']);
end
border = table2array(border);
c = fitlm([GDP_i,GDP_j, dist_ij, SumGdp, border,origin_AUS, origin_AUT, origin_BEL, origin_CAN, origin_CHE, origin_CHL, origin_CHN, origin_CZE, origin_DEU, origin_DNK, origin_ESP, origin_EST, origin_FRA, origin_GBR, origin_GRC, origin_IRL, origin_ISL, origin_JPN, origin_MEX, origin_NOR, origin_NZL, origin_POL, origin_PRT, origin_SVK, origin_SWE, origin_TUR, origin_USA, destination_AUS, destination_AUT, destination_BEL, destination_CAN, destination_CHE, destination_CHL, destination_CHN, destination_CZE, destination_DEU, destination_DNK, destination_ESP, destination_EST, destination_FRA, destination_GBR, destination_GRC, destination_IRL, destination_ISL, destination_JPN, destination_MEX, destination_NOR, destination_NZL, destination_POL, destination_PRT, destination_SVK, destination_SWE, destination_TUR, destination_USA], export_ij, "linear");