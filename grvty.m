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
gdp = cell2mat(columnVectors{4});
gdp = reshape(gdp,[],28);
dist = reshape(dist,[],28);
export = cell2mat(columnVectors{5});
export = reshape(export,[],28)';
modifiedNames = strcat(common_values, '_dist');
dist = array2table(dist, 'VariableNames', modifiedNames);
dist.Properties.RowNames = common_values;
modifiedNames = strcat(common_values, '_export');
export = array2table(export, 'VariableNames', modifiedNames);
export.Properties.RowNames = common_values;
modifiedNames = strcat(common_values, '_gdp');
gdp = array2table(gdp, 'VariableNames', modifiedNames);
gdp.Properties.RowNames = common_values;
gravity = [dist, gdp, export];
clearvars -except gravity