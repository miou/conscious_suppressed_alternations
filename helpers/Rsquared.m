function rsquared = Rsquared(y_actual,y_predicted)

nan_predictions = isnan(y_predicted); %Ignore nan predictions
% Sum of squared residuals
SSR = sum((y_predicted(~nan_predictions) - y_actual(~nan_predictions)).^2);
% Total sum of squares
TSS = sum(((y_actual(~nan_predictions) - mean(y_actual(~nan_predictions))).^2));
% R squared
rsquared = 1 - SSR/TSS;
