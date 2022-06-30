function wpctile = weigh_prctile(X,percentiles,variant,mode,weights)
% Weighted percentiles
% variant - 1,2 or 3
% mode - 'weighted' or 'unweighted'

%% Calculations
% Number of data points
n_data = numel(X);
% Order data points
[ordered_X,order_IX] = sort(X);

switch mode
    case 'weighted'
        total_weights = sum(weights);
        
        % Determine the rank
        switch variant
            case 1
                C = 0.5;
            case 2
                C = 1;
            case 3
                C = 0;
            otherwise
                error('Variant is not supported');
        end
        
        cum_ordered_weights = ((cumsum(weights(order_IX)) - C.*weights(order_IX))./(total_weights + (1-2*C).*weights(order_IX))).*100;
        
        wpctile = nan(size(percentiles));
        
        % First solve for percentiles at or beyond bounds
        wpctile(percentiles <= cum_ordered_weights(1)) = ordered_X(1);
        wpctile(percentiles >= cum_ordered_weights(end)) = ordered_X(end);

        % Find exact matches
        wpctile(ismember(percentiles,cum_ordered_weights)) = ordered_X(ismember(cum_ordered_weights,percentiles));
        % Compute for no matches
        for pct = percentiles(ismember(percentiles,cum_ordered_weights) == 0 & isnan(wpctile) == 1)
            antecedent_datapoint_ranks = find(diff((cum_ordered_weights-pct)./abs(cum_ordered_weights-pct)) > 0);
            post_datapoint_ranks = antecedent_datapoint_ranks + 1;

            wpctile(percentiles == pct) = ordered_X(antecedent_datapoint_ranks) + ((pct - cum_ordered_weights(antecedent_datapoint_ranks))/(cum_ordered_weights(post_datapoint_ranks)-cum_ordered_weights(antecedent_datapoint_ranks)))*(ordered_X(post_datapoint_ranks) - ordered_X(antecedent_datapoint_ranks));
        end
    case 'unweighted'
        % Determine the rank
        switch variant
            case 1
                % Same as prctile function
                ordered_X_percentiles = (100/n_data).*((1:n_data) - 0.5);

                wpctile = nan(size(percentiles));

                % First solve for percentiles at or beyond bounds
                wpctile(percentiles <= ordered_X_percentiles(1)) = ordered_X(1);
                wpctile(percentiles >= ordered_X_percentiles(end)) = ordered_X(end);

                % Find exact matches
                wpctile(ismember(percentiles,ordered_X_percentiles)) = ordered_X(ismember(ordered_X_percentiles,percentiles));

                % Compute for no matches
                for pct = percentiles(ismember(percentiles,ordered_X_percentiles) == 0 & isnan(wpctile) == 1)
                    antecedent_datapoint_ranks = find(diff((ordered_X_percentiles-pct)./abs(ordered_X_percentiles-pct)) > 0);
                    post_datapoint_ranks = antecedent_datapoint_ranks + 1;

                    wpctile(percentiles == pct) = ordered_X(antecedent_datapoint_ranks) + n_data*((pct - ordered_X_percentiles(antecedent_datapoint_ranks))/100)*(ordered_X(post_datapoint_ranks) - ordered_X(antecedent_datapoint_ranks));
                end

                return
            case 2
                % NumPy, EXCEL (PERCENTILE.INC)
                datapoint_ranks = ((percentiles./100).*(n_data - 1)) + 1;
            case 3
                % National Institute of Standards and Technology (NIST) recommended, EXCEL (PERCENTILE.EXC)
                datapoint_ranks = (percentiles./100).*(n_data + 1);
            otherwise
                error('Variant is not supported');
        end

        % For variants 2 and 3
        antecedent_datapoint_ranks = floor(datapoint_ranks);
        antecedent_datapoint_ranks(antecedent_datapoint_ranks < 1) = 1;

        post_datapoint_ranks = antecedent_datapoint_ranks + 1;
        post_datapoint_ranks(post_datapoint_ranks > n_data) = n_data;

        wpctile = ordered_X(antecedent_datapoint_ranks) + mod(datapoint_ranks,1).*(ordered_X(post_datapoint_ranks) - ordered_X(antecedent_datapoint_ranks));
    otherwise
        error('Mode not supported.');
end
