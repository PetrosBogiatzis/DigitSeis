function y=digitize_region(A,tol)
% digitize columnwise image A using tolerance tol
% Petros Bogiatzis 2014.
% y is the digitization output.

b=A>tol; % A has values from 0 to 255
[r,~]=find(b);
[rA,cA]=size(A);
R=zeros(rA,cA,'single');
R(b)=r;
y=sum(R.*A.^2,1)./sum(A.^2,1);
y(sum(b)<1)=nan;
end
