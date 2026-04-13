% Ask the user for the specific words
words = input('Enter the words to prepend "obj." to (separated by spaces): ', 's');

% Split the input into individual words
wordList = strsplit(words);
filename = 'appendObj.txt';

% Read the content of the text file
fileID = fopen(filename, 'r');
textData = fscanf(fileID, '%c');
fclose(fileID);

% Replace each specific word with 'obj.word'
newTextData = textData;
for i = 1:numel(wordList)
    word = wordList{i};
    newTextData = strrep(newTextData, word, ['obj.', word]);
end

% Write the modified text back to the file
fileID = fopen(filename, 'w');
fprintf(fileID, '%s', newTextData);
fclose(fileID);

disp('Modification complete.'); % Notify the user
