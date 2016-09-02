function [ybest,ystd]=digitize_trace_and_tickmarks(stripe1,stripe0,bstripe1,bstripe0)
% THIS SOFTWARE IS PROVIDED BY THE AUTHORS ``AS IS'' AND ANY EXPRESS OR 
% IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
% WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
% ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY 
% DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
% DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE 
% GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
% WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
% OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
% EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%
%
% Version 2.5
% (as from DigitSeis Version 0.72)
% uses optimization instead of grid search.
% Petros Bogiatzis.

global r1 c1 r0

tol=1; % between 0 and 255

[r1,c1]=size(stripe1);
[r0,c0]=size(stripe0);

stripe1(~bstripe1)=false;
stripe0(~bstripe0)=false;

if c0~=c1
    error('stripes have different lengths')
end

opts=optimset('TolFun',1e-6,'TolX',0.4);%,'PlotFcns',{@optimplotx,@optimplotfval,@optimplotfunccount});

% bounds
[~,ix1]=max(sum(bstripe1,2));
[~,ix2]=max(sum(bstripe0,2));
x1=- max( (r0-round(r1/2)),abs(ix1-ix2));
x2=  max( (r1-round(r1/2)),abs(ix1-ix2));
x = fminbnd(@(x) objective_fun(x,stripe0, stripe1,bstripe0, bstripe1,tol),x1,x2,opts);

FUSED=create_fused_image(x,stripe0, stripe1,bstripe0, bstripe1); 
[ybest,ystd]=digitize_regionSTD(single(FUSED),tol);
end


function c=objective_fun(x,stripe0, stripe1,bstripe0, bstripe1,tol)
        
    FUSED=create_fused_image(x,stripe0, stripe1,bstripe0, bstripe1);
    y=digitize_region(single(FUSED),tol)';
         
    % calculate derivative to evaluate digitization
    c=mean(abs(diff((y(~isnan(y)))))); 
    
    if isnan(c)||isinf(c), c=realmax; end;
     
end




function FUSED=create_fused_image(x,stripe0, stripe1,bstripe0, bstripe1)
  global r1 c1 r0

    i=round(x);
    if i<0
     rows_stripe0= max(1,-i+1) : r0;
    else
     rows_stripe0=    1 : min(r0,r1-i);
    end
    
    bSL=false([r1 c1]);

    rowsSL=max(0,i)+1:min(r1,max(0,i)+numel(rows_stripe0));
    bSL(rowsSL,:)=bstripe0(rows_stripe0,:);

    % sift stripe0 and  bstripe0 with respect to stripe1
    SL=zeros([r1 c1],'uint8');
    SL(rowsSL,:)=stripe0(rows_stripe0,:);
    
    
    % calculate masks
    MASK1= bstripe1 & ~bSL;
    MASK2= ~bstripe1 & bSL;
    MASK3= bstripe1 & bSL;
    
    FUSED=zeros([r1 c1],'uint8');
    FUSED(MASK1)=stripe1(MASK1);
    FUSED(MASK2)=SL(MASK2);
    FUSED(MASK3)=max(stripe1(MASK3),SL(MASK3));
end




