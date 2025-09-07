%% (7,4) Hamming code with codeword length n=7 and message length k=4:
%%%%%%%%%%%%%%%%%%%%%%% Message input and encoding %%%%%%%%%%%%%%%%%%%%%%%%
% Ask the user to enter a 4-bit binary message
message = input('Enter a 4-bit binary message (Ex: [1 0 1 1]): ');

% Check the user input
if length(message) ~= 4 || any(message ~= 0 & message ~= 1)
    error('Input must be a 4-bit binary vector.');
end

% Encoding the message
encoded_message = hamming_encoder(message);

% the encoded message
disp('Encoded message:');
disp(encoded_message);

%%%%%%%%%%%%%%%%%%%% Adding AWGN to the transmitted message %%%%%%%%%%%%%%%%%%%
% Asking the user to enter a value for the SNR
SNR = input('Enter a value for the signal to noise ratio (SNR): ');
% Adding AWGN noise to the encoded message
msg_with_AWGN = awgn(encoded_message, SNR, 'measured');

% the message with AWGN
disp('Message with AWGN:');
disp(msg_with_AWGN);

%%%%%%%%%%%%%%%%%%%%%% Recieved message decoding %%%%%%%%%%%%%%%%%%%%%%%%%%
% Decoding the recieved message
% a binary vector is sent to the decoding function of element = 
% 1 if it is > 0.5 in msg_with_AWGN and 0 otherwise.
decoded_message = hamming_decoder(msg_with_AWGN > 0.5); % threshold = 0.5

% Results
disp('Original message:');
disp(message);
disp('Encoded message:');
disp(encoded_message);
disp('Noisy message:');
disp(msg_with_AWGN);
disp('Decoded message:');
disp(decoded_message);

%%%%%%%%%%%%%%%%%%%%plots for BER versus SNR %%%%%%%%%%%%%%%%%%%%%%%%
%% Parameters
SNR_range = 0:1:10; % SNR values from 0 to 10 dB
num_bits = 1e6; % Total number of bits

%% BER Calculation
ber_hamming = zeros(1, length(SNR_range));
ber_uncoded = zeros(1, length(SNR_range));

for index = 1:length(SNR_range)
    SNR = SNR_range(index);
    
    % Generate random binary messages
    message = randi([0, 1], num_bits/4, 4); % (7,4) Hamming works on 4-bit blocks
    
    %% (7,4) Hamming Coded System
    % Encode the message
    encoded_message = arrayfun(@(row) hamming_encoder(message(row, :)),(1:size(message, 1))', 'UniformOutput', false);
    encoded_message = cell2mat(encoded_message);
    
    % Add AWGN
    noisy_message_hamming = awgn(encoded_message, SNR, 'measured');
    
    % Decode the message
    received_message_hamming = noisy_message_hamming > 0.5; % Threshold at 0.5
    decoded_message = arrayfun(@(row) hamming_decoder(received_message_hamming(row, :)),(1:size(message, 1))', 'UniformOutput', false);
    decoded_message = cell2mat(decoded_message);
    
    % Compute BER for Hamming
    ber_hamming(index) = sum(sum(decoded_message ~= message)) / num_bits;

    %% Uncoded System
    % Generate uncoded binary message
    uncoded_message = randi([0, 1], 1, num_bits);
    
    % Add AWGN
    noisy_message_uncoded = awgn(uncoded_message, SNR, 'measured');
    
    % Decode the message
    received_message_uncoded = noisy_message_uncoded > 0.5;
    
    % Compute BER for uncoded
    ber_uncoded(index) = sum(received_message_uncoded ~= uncoded_message) / num_bits;
end
%% Plotting the BER vs SNR Curve
figure;
semilogy(SNR_range, ber_hamming, '-o', 'LineWidth', 2);
hold on;
semilogy(SNR_range, ber_uncoded, '-x', 'LineWidth', 2);
grid on;
xlabel('SNR (dB)');
ylabel('Bit Error Rate (BER)');
title('BER vs. SNR for Hamming Code vs. Uncoded');
legend('(7,4) Hamming Coded', 'Uncoded');

%% End-to-End Communication System
    %% Process Text File
    % Read the entire file as text
    text = fileread('C:\Users\hp\Downloads\Test_text_file.txt');
    data = lower(text);     % Make all small to be case insensitive

    %% Step 1: Source Encoding (Huffman Encoding)
    all_chars = ['abcdefghijklmnopqrstuvwxyz,./()- '];
    num_chars = length(all_chars);

    % Count occurrences of each character
    char_count = zeros(1, num_chars);
    for i = 1:num_chars
        char_count(i) = sum(data == all_chars(i));
    end

    % Calculate probabilities
    char_prob = char_count / sum(char_count);

    % Huffman Encoding
    [encoded_data, huffman_tree, huffman_table] = Huffman_encode(all_chars, char_prob, data);

    %% Step 2: Channel Encoding (Hamming Code)
    % Convert encoded data to binary
    binary_data = char(encoded_data) - '0'; % Convert string to binary array

    % Pad binary data to make it divisible by 4
    if mod(length(binary_data), 4) ~= 0
        binary_data = [binary_data, zeros(1, 4 - mod(length(binary_data), 4))];
    end

    % Reshape into 4-bit blocks
    binary_data = reshape(binary_data, 4, []).';

    % Apply Hamming (7,4) encoding
    encoded_message = arrayfun(@(row) hamming_encoder(binary_data(row, :)), 1:size(binary_data, 1), 'UniformOutput', false);
    encoded_message = cell2mat(encoded_message);

    %% Step 3: Channel Simulation with AWGN
    SNR_values = [5, 10, 15]; % SNR values in dB
    results = struct();

    for i = 1:length(SNR_values)
        SNR = SNR_values(i);

        % Add AWGN
        noisy_message = awgn(encoded_message, SNR, 'measured');

        % Reshape noisy_message
        received_message = reshape(noisy_message > 0.5, [], 7); 

        % Decode the received message
        decoded_message = arrayfun(@(row) hamming_decoder(received_message(row, :)), 1:size(received_message, 1), 'UniformOutput', false);
        decoded_message = cell2mat(decoded_message);

        % Flatten decoded binary data
        decoded_binary = reshape(decoded_message.', 1, []); 

        % Remove padding
        decoded_binary = decoded_binary(1:length(encoded_data));

        % Convert binary data back to string
        received_data = char(decoded_binary + '0');

        % Huffman Decoding
        decoded_text = Huffman_decode(received_data, huffman_tree);

        % Adjust the length of decoded_text
        min_length = min(length(decoded_text), length(data));
        decoded_text = decoded_text(1:min_length);
        input_text_trimmed = data(1:min_length);

        % Store results
        results(i).SNR = SNR;
        results(i).DecodedText = decoded_text;
        results(i).Errors = sum(decoded_text ~= input_text_trimmed);
    end

    %% Without Channel Coding
    results_without_coding = struct();

    for i = 1:length(SNR_values)
        SNR = SNR_values(i);

        % Add AWGN directly to Huffman-encoded binary data
        noisy_data = awgn(double(encoded_data) - '0', SNR, 'measured');
        received_data = char((noisy_data > 0.5) + '0');

        % Huffman Decoding
        decoded_text_no_coding = Huffman_decode(received_data, huffman_tree);

        % Adjust length of decoded text
        min_length = min(length(decoded_text_no_coding), length(data));
        decoded_text_no_coding = decoded_text_no_coding(1:min_length);
        input_text_trimmed = data(1:min_length);

        % Store results
        results_without_coding(i).SNR = SNR;
        results_without_coding(i).DecodedText = decoded_text_no_coding;
        results_without_coding(i).Errors = sum(decoded_text_no_coding ~= input_text_trimmed);
    end

    %% Open file for writing results
    fileID = fopen('results.txt', 'w');

    %% Display Results with Channel Coding
    for i = 1:length(SNR_values)
        fprintf(fileID, 'SNR: %d dB\n', results(i).SNR);
        fprintf(fileID, 'With Channel Coding - Errors: %d\n', results(i).Errors);
        fprintf(fileID, 'With Channel Coding - Decoded Text:\n%s\n', results(i).DecodedText);
    end

    %% Results without Channel Coding
    for i = 1:length(SNR_values)
        fprintf(fileID, '\nSNR: %d dB\n', results_without_coding(i).SNR);
        fprintf(fileID, 'Without Channel Coding - Errors: %d\n', results_without_coding(i).Errors);
        fprintf(fileID, 'Without Channel Coding - Decoded Text:\n%s\n', results_without_coding(i).DecodedText);
    end

    %% Close the file
    fclose(fileID);


%% Encoding function
function codeword = hamming_encoder(message)
    % Hamming (7,4) generator matrix
    % G = [I|P] of size n*k, as I is 4*4 identity matrix and P is the parity bits of
    % length(n-k), n = codeword length(7) and k = message length(4)
    
    G = [1 0 0 0 1 1 0;
         0 1 0 0 1 0 1;
         0 0 1 0 1 1 1;
         0 0 0 1 0 1 1];
    
    % the codeword = message * G mod 2
    % Encode the message using matrix multiplication
    codeword = mod(message * G, 2);
end

%% Decoding function
function decoded_message = hamming_decoder(recieved_word) % syndrome decoder
    % the parity-check matrix of size 3*7, 3 is the parity bits(r) length and
    % 7 is the codewi=ord length
    % each column of the H matrix is a binary representation of the column index
    H = [0 0 0 1 1 1 1;
         0 1 1 0 0 1 1;
         1 0 1 0 1 0 1];
    
    % Calculating the syndrome as syndrome(1*r) = Y*(H)T as Y(1*n) is the recieved
    % codeword and (H)T(n*r) is the transpose of the matrix H
    % syndrome indicates an error in the received codeword: if the syndrome is all zeros (no error)
    % or it is non-zero (presence of an error)
    syndrome = mod(recieved_word * H', 2); 

    % error position mapping
    % converting syndrome from binary to decimal value that represents the position of bit error
    error_position = bi2de(syndrome, 'left-msb');
    
    % If there is an error, bit at the error position is flipped.
    if error_position > 0
        recieved_word(error_position) = mod(recieved_word(error_position) + 1, 2);
    end
    
    % Extracting the original 4-bit message from the corrected codeword
    decoded_message = recieved_word(1:4);
end

%%
function [encodedData, huffmanTree, huffman_table] = Huffman_encode(all_chars, char_prob, data)
    % Create initial leaf nodes
    nodes = num2cell(char_prob);
    symbol_nodes = num2cell(all_chars);

    % Build the Huffman tree
    while numel(nodes) > 1
        [nodes, idx] = sort(cell2mat(nodes), 'ascend');
        nodes = num2cell(nodes);
        nodes = nodes(idx);
        symbol_nodes = symbol_nodes(idx);
        newNodeProb = nodes{1} + nodes{2};
        newNodeSymbols = {symbol_nodes{1}, symbol_nodes{2}};
        nodes = [{newNodeProb}, nodes(3:end)];
        symbol_nodes = [{newNodeSymbols}, symbol_nodes(3:end)];
    end
    huffmanTree = symbol_nodes{1};

    % Generate Huffman Codes
    codes = generateCodes(huffmanTree, '');
    huffman_table = table({codes.symbol}', {codes.code}', 'VariableNames', {'Symbol', 'HuffmanCode'});

    % Encode Text
    encodedData = '';
    for i = 1:length(data)
        codeIndex = find(strcmp({codes.symbol}, data(i)), 1);
        if ~isempty(codeIndex)
            encodedData = [encodedData, codes(codeIndex).code];
        end
    end
end
%%
function codes = generateCodes(node, code)
    if iscell(node)
        left = node{1};
        right = node{2};
        codes = [generateCodes(left, [code, '0']), generateCodes(right, [code, '1'])];
    else
        codes = struct('symbol', node, 'code', code);
    end
end
%%
function decodedData = Huffman_decode(encodedData, huffmanTree)
    decodedData = '';
    temp_node = huffmanTree;
    for i = 1:length(encodedData)
        if encodedData(i) == '0'
            temp_node = temp_node{1};
        else
            temp_node = temp_node{2};
        end
        if ~iscell(temp_node)
            decodedData = [decodedData, temp_node];
            temp_node = huffmanTree;
        end
    end
end

