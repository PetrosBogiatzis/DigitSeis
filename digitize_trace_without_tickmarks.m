function ybest=digitize_trace_without_tickmarks(stripe,bstripe)
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
% This is just digitizing the image asuming no time-marks.
% Petros Bogiatzis.

global r1 c1

tol=1; % between 0 and 255

[r1,c1]=size(stripe);
stripe(~bstripe)=false;

ybest=digitize_region(single(stripe),tol);
end


function y=digitize_region(A,tol)
b=A>tol; % A has values from 0 to 255
[r,~]=find(b);
[rA,cA]=size(A);
R=zeros(rA,cA,'single');
R(b)=r;
y=sum(R.*A.^2,1)./sum(A.^2,1);
y(sum(b)<1)=nan;
end



