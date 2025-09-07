% Read the entire file as text
text = fileread('C:\Users\hp\Downloads\Test_text_file.txt');
%fprintf(text)
Data = lower(text);    %make all small to be case insenstive

all_chars = ['abcdefghijklmnopqrstuvwxyz,./()- '];
num_of_charachters = length(all_chars);
disp(num_of_charachters)

char_count = zeros(1, num_of_charachters);
disp(char_count)

% Count occurrences of each character
for i = 1:num_of_charachters
    char_count(i) = sum(Data == all_chars(i));
end

total_chars = sum(char_count);
% Calculate probabilities
charprob = char_count / total_chars;

for i = 1:num_of_charachters
    fprintf('Character %c: Probability %.4f\n', all_chars(i), charprob(i));
end

% calculating Shannon Entropy
char_entropy = 0;
for i = 1:num_of_charachters
    if charprob(i) > 0  % to avoid log(0)
        char_entropy = char_entropy + (charprob(i) * log2(1 / charprob(i)));
    end
end

% Display the Shannon entropy
disp(['Shannon Entropy: ', num2str(char_entropy)]);

%the number of bits/symbol for a fixed length code (log2(size))
bits_per_symbol = ceil(log2(33));
fprintf('Number of bits/symbol for a fixed length code is %d\n', bits_per_symbol);

% fixed length code efficiency
efficiency = (char_entropy/bits_per_symbol)*100;
fprintf('Fixed length code efficiency: %.2f%%\n', efficiency);

% Huffman encoding
[encodedData, huffmanTree, huffman_table]=Huffman_encode(all_chars, charprob, Data);

% Huffman decoding using Huffman tree
decodedData = Huffman_decode(encodedData, huffmanTree);

%write decoded data to a text file 
writeTextFile('C:\Users\hp\Downloads\Decoded_text_file.txt', decodedData);

%the efficiency of the Huffman code
avgHuffmanLength = avg_length(all_chars, charprob, huffman_table);

Huffman_efficiency = (char_entropy/avgHuffmanLength)*100;
fprintf('Huffman Efficiency: %.2f%%\n', Huffman_efficiency);
%-------------------------------------------------------------------------
% Prepare symbol-probability pairs for Shannon-Fano encoding
symbols = cell(num_of_charachters, 2);
for i = 1:num_of_charachters
    symbols{i, 1} = all_chars(i);
    symbols{i, 2} = charprob(i);
end

% Sort symbols by probability in descending order
symbols = sortrows(symbols, -2);
shannonFanoCodes = Shannon_Fano_encoding(symbols);
% print Shannon-Fano Codes
charsf = {shannonFanoCodes.symbol}';  %
codesSF = {shannonFanoCodes.code}';      

% Create a table for the display
disp('Shannon-Fano Codes:');
shanon_table = table(charsf, codesSF, 'VariableNames', {'Symbol', 'ShannonFanoCode'});
disp(shanon_table);
% Encode text using Shannon-Fano codes
encodedDataSF = '';
for i = 1:length(Data)
    % Find the code for each character
    codeIndex = find(strcmp({shannonFanoCodes.symbol}, Data(i)), 1);
    if ~isempty(codeIndex)
        encodedDataSF = [encodedDataSF, shannonFanoCodes(codeIndex).code];
    end
end

% Display the Shannon-Fano Encoded Data
disp('Shannon-Fano Encoded Data:');
disp(encodedDataSF);
% Decode the encoded data using Shannon-Fano decoder
decodedTextShannon = Shannon_Fano_decoding(encodedDataSF, shannonFanoCodes);
disp(decodedTextShannon);
% calc the efficiency of shannon
avgshannonLength = shanon_avg_length(all_chars, charprob, shanon_table);
shannon_efficiency = (char_entropy/avgshannonLength)*100;
fprintf('shannon Efficiency: %.2f%%\n', shannon_efficiency);

%compare the efficiency of shannon and huffman
if shannon_efficiency > Huffman_efficiency
    disp("shannon is more efficient in this case");
else 
    disp("Huffman is more efficient in this case");
end
%-------------------------------------------------------------------------------------

% Function for Huffman Encoding
function [encodedData, huffmanTree, huffman_table] = Huffman_encode(all_chars, charprob, Data)
   
    % Step 1: Create initial leaf nodes
    nodes = num2cell(charprob);      %convert elements of array into cells to represent the nodes
    symbol_nodes = num2cell(all_chars);

    % Step 2: Build The Huffman tree
    while numel(nodes) > 1
        % sort nodes by probability ascending
        [nodes_sorted,idx] = sort(cell2mat(nodes), 'ascend');

       % Convert back to a cell array (sorted)
        nodes = num2cell(nodes_sorted);

        nodes = nodes(idx);
        symbol_nodes = symbol_nodes(idx);

        % Merge two nodes with the lowest probabilities
        newNodeProb = nodes{1} + nodes{2};  % Combine probabilities
        newNodeSymbols = {symbol_nodes{1}, symbol_nodes{2}};  % Combine symbols
        
        % Remove the two nodes and insert the new node
        nodes = [{newNodeProb}, nodes(3:end)];
        symbol_nodes = [{newNodeSymbols}, symbol_nodes(3:end)];
    end
    huffmanTree = symbol_nodes{1};

    % Step 3: Generate Huffman Codes
    codes = generateCodes(huffmanTree, '');

   % Display Huffman Codes i
disp('Generated Huffman Codes:');
symbols = {codes.symbol};  
codes_str = {codes.code};  

% Create a table with symbols and codes
huffman_table = table(symbols', codes_str', 'VariableNames', {'Symbol', 'HuffmanCode'});
disp(huffman_table);

    
    % Step 4: Encode Text
    encodedData = '';
    for i = 1:length(Data)
        codeIndex = find(strcmp({codes.symbol}, Data(i)), 1);
        if ~isempty(codeIndex)
            encodedData = [encodedData, codes(codeIndex).code];
        end
    end

    % Display Encoded Data
    disp('Encoded Data:');
    disp(encodedData);
end    

% Recursive function to generate Huffman codes
function codes = generateCodes(node, code)
    if iscell(node)  
        left = node{1};  
        right = node{2};
        codes = [generateCodes(left, [code, '0']), generateCodes(right, [code, '1'])];
    else
        codes = struct('symbol', node, 'code', code); 
    end
end


% Function for Huffman Decoding using Huffman tree
function decodedData = Huffman_decode(encodedData, huffmanTree)
    decodedData = '';
    temp_node = huffmanTree;
    
    % traversing the bits of encodedData to know the symbol
    for i = 1:length(encodedData)
        if encodedData(i)== '0'
            temp_node=temp_node{1}; %left subtree
        else
            temp_node=temp_node{2}; %right subtree
        end
        %check if the node is leaf to stop and add the decoded data
        if ~iscell(temp_node)
            % adding the decoded character
            decodedData=[decodedData , temp_node]; 
            %resetting the node position to start fron the root 
            temp_node=huffmanTree;
        end
    end
end

% write to a text file
function writeTextFile(name, data)
    % open the file to write
    file = fopen(name, 'w');
    %copy text from data as a string
    fprintf(file, '%s' , data);
    fclose(file);
end


% calculating the Huffman code average length
function avgHuffmanLength=avg_length(all_chars, charprob, huffmanTable)
    avgHuffmanLength=0;
    for i = 1:length(all_chars)
        % finding the position of code of each character 
        codePosition = find(strcmp(huffmanTable.Symbol,all_chars(i)),1);
        %length of each character's code
        code_length = length(huffmanTable.HuffmanCode{codePosition});
        avgHuffmanLength = avgHuffmanLength + (code_length * charprob(i));
    end
end
% calculating the shannon code average length
function avgLength = shanon_avg_length(all_chars, charprob, codeTable)
    avgLength = 0;
    for i = 1:length(all_chars)
        % Find the position of code for each character
        codePosition = find(strcmp(codeTable.Symbol, all_chars(i)), 1);
        % Length of each character's code
        code_length = length(codeTable.ShannonFanoCode{codePosition});
        avgLength = avgLength + (code_length * charprob(i));
    end
end

% function to shannon_fano encoder
function shannonFanoCodes = Shannon_Fano_encoding(symbols, code)
    if nargin < 2
        code = '';
    end

    if size(symbols, 1) == 1
        shannonFanoCodes = struct('symbol', symbols{1, 1}, 'code', code);
        return;
    end

    % Calculate total probability
    totalProb = sum(cell2mat(symbols(:, 2)));

    % Determine split index
    accumProb = 0;
    splitIndex = 0;
    for i = 1:size(symbols, 1)
        accumProb = accumProb + symbols{i, 2};
        if accumProb >= totalProb / 2
            splitIndex = i;
            break;
        end
    end

    % Split into left and right
    leftSymbols = symbols(1:splitIndex, :);
    rightSymbols = symbols(splitIndex + 1:end, :);

    % Recursively encode left and right branches
    leftCodes = Shannon_Fano_encoding(leftSymbols, [code, '0']);
    rightCodes = Shannon_Fano_encoding(rightSymbols, [code, '1']);

    % Combine the codes
    shannonFanoCodes = [leftCodes; rightCodes];
end
% Shannon-Fano Decoder
function decodedText = Shannon_Fano_decoding(encodedText, shannonFanoCodes)
    % Reverse the Shannon-Fano code table for easy lookup
    reverseCodes = containers.Map({shannonFanoCodes.code}, {shannonFanoCodes.symbol});
    
    decodedText = '';
    currentCode = '';

    % Traverse the encoded 
    for i = 1:length(encodedText)
        currentCode = [currentCode, encodedText(i)];

        % Check if current code matches a symbol in the reverse map
        if isKey(reverseCodes, currentCode)
            decodedText = [decodedText, reverseCodes(currentCode)];
            currentCode = '';  % Reset current code after finding a match
        end
    end
end






