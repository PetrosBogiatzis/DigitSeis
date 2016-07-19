function y = median_nonan( x )
%  calculates the median in a vector. Leaving out the nans
% Petros Bogiatzis 2014
y=median(x(~isnan(x)));

end

