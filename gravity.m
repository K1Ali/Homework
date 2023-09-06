export = readtable('C:\Users\Ali Kazimov\Downloads\Export.csv');
GDP = readtable('C:\Users\Ali Kazimov\Downloads\GDP.xls');
dist = readtable('C:\Users\Ali Kazimov\Downloads\dist_cepii.xls');
GDP.Properties.VariableNames(5:15) = cellstr(num2str(export.TIME(1:11)));
MAIN=export(strcmp(export.Flow, 'Exports'), :);
MAIN=MAIN(strcmp(MAIN.Frequency, 'Annual'), :);
MAIN(:, setdiff(1:size(MAIN, 2), [1,5,10,17])) = [];
MAIN.export = MAIN.Value;
MAIN.Value = [];
for i = 1:size(MAIN, 1)
    matchingRowIdx = find(strcmp(dist.iso_o,MAIN.LOCATION(i)) & strcmp(dist.iso_d, MAIN.PARTNER(i)));
    if ~isempty(matchingRowIdx)
        MAIN.dist(i) = dist{matchingRowIdx, 11};
    end
end
for i = 1:size(MAIN, 1)
     matchIdx = strcmp(GDP.Year, MAIN.LOCATION{i});
     if any(matchIdx)
         if ismember(num2str(MAIN.Time(i)), GDP.Properties.VariableNames)
             MAIN.GDP_loc(i) = GDP{matchIdx, num2str(MAIN.Time(i))};
         end
     end
end
for i = 1:size(MAIN, 1)
     matchIdx = strcmp(GDP.Year, MAIN.PARTNER{i});
     if any(matchIdx)
         if ismember(num2str(MAIN.Time(i)), GDP.Properties.VariableNames)
             MAIN.GDP_par(i) = GDP{matchIdx, num2str(MAIN.Time(i))};
         end
     end
end
MAIN(MAIN.dist == 0 | MAIN.GDP_loc == 0 | MAIN.GDP_par == 0, :) = [];
%% I do not know what should data look like according to your 3rd task of
%assignment. I interpret it as transpose of our panel data. So I did
%this.
M = rows2vars(MAIN);