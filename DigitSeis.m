function DigitSeis % for opening older analysis if replace the name of the function with DigitizeSeis (not the name of the m-file)
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
%  DigitSeis uses rgb2hsv_fast.m that can be found at
%  http://www.mathworks.com/matlabcentral/fileexchange/15985-fast-rgb2hsv/content/rgb2hsv_fast.m
%  DigitSeis uses writesac.m function that can be found at SAC
%  distributions: %  http://ds.iris.edu/ds/nodes/dmc/forms/sac/
%
%  Digitseis  is on the Github
%  https://github.com/PetrosBogiatzis/DigitSeis
%
%  Version 0.72
%   - Remove region in Correct classification gui (binary image)
%   - Added contrast interactive tool in correct trace gui
%   - Added buttons in the "select traces to digitize" dialog for fast
%     selections.
%   - changed in digitize_trace_and_tickmarks.m the bounds of minimization to be more robust when objects are
%     not in the middle
%   - minor bug fixes and improvements. 
% 
%  Version 0.692
%   - Bug fixes in correct trace gui (zoom out, change classification, others)
%   - performance improvements
%   - when applying the corrected trace, there is an option to replace only
%     the numeric values (skip NaNs).
%
%  Version 0.69
%    - Now digitization returns also the std of the digitized column. It is
%      included in a second block of data i.e., DATA2 at the SAC structure.
%       > Files digitize_trace_without_tickmarks.m,
%         digitize_trace_and_tickmarks.m have also changed.
%       > File digitize_regionSTD.m has been added
%    - minor improvements - bug fixes when loading previous analyses
%
%  Version 0.68
%    - Added the option to correct portion of a trace instead of the whole
%      trace.
%    - minor modifications here and there.
%
%  Version 0.67
%    - Added an input dialog that allows purging all small objects in binary
%      image during the identification of traces and time marks procedure.
%    - Added option to filter the image for get ridding the salt & pepper
%      noise using either 2-D median or Wiener filter.
%    - Added a button to reset zoom to the whole image  in the "edit
%      classification" gui
%    - Added a button to purge red-noise objects at the "edit classification" gui
%
%  Version 0.65
%    - Support for seismograms without time marks added. -->set time mark
%      length < 0 to indicate that there are no time marks.
%    - Added the option the user to select the traces to be digitized.
%    - fixed small bugs here and there
%
%   Version 0.6
%   - object asignments to traces now allows for multiple assignments per object
%   - minor bugs fixed
%
%   Version 0.55
%   - error handling imrpoved in the case of tight trunccated image
%   - minor improvements in individual trace correction.
%
%   Version 0.54
%   - Bug with additional instances of buttons in single trace tratment corrected
%   - minor bugs corrected
%
%   Version 0.53
%   - Bugs fixed with assignments
%   - Remove background button-function added
%
%   Version 0.52
% - Corrected bug of previous version that sometimes was giving error
%   in timing when timarks down
% - Assignemnt of objects to traces moved under the classification
%   proccedure. S structrure now includes the new field TraceNum which stores
%   the trace that this object is assigned to. It is empty for red objects
%   You should 1st complete the classification and then start working with
%   assignments.
% - Added the option for the user to correct object assignments.
% - other minor bug fixes.
%
% Version 0.51
% - Corrected function name to DigitSeis from DigitizeSeis
% - Bugs corrected, including y' and index-0 error in tightly cropped images.
% - Corrected bug with load file
% - Corrected timing bug
% - Edit classification GUI improved.
%      - put recalculate classification button and level spinner to the
%        right in order to avoid accidental engagement
%      - put confirmation dialog to recalculate classification.
%      - added option to use a different image just for the classification
%        purpose (button added, including confirmation dialog).
%      - added functionality to add true pixels instead of just removing
%        them.
%      - added undo option for add & remove pixels along path.
%      - added button to deal with RGB- colorblindness as an additional
%        color scheme.
%
% Petros Bogiatzis.




%clear all
%global H HIM I0 output_message ptrace pt_traces pt_traceLABEL Time ftrend ftrend_tick S sumI ww pt_start_time pt_end_time p_tick_1st p_tick_last tick_length_lim
global H I0 output_message tick_length_lim

tick_length_lim=0.2; % 20per cent  of the input length, change according the case % to be included as an option in future versions

% H:  Structure with handles for figure, uicontrols and axes.
% I0: The current version of the seismogram image.
% pt_traces: Handle to the lines along traces
% pt_tticks: handle to lines along time tickmarks. INACTIVE
% ftrend: Fit object that describes the trend of the main traces
% ftrend_tick: fit object that describes the trend of time tickmarks.
% output_message messages list for the output window


I0=[];

output_message={};
H.f1=figure('Name','DigitizeSeis','NumberTitle','off','Color','w','Units','Pixels',...
    'Position',.8*get(0,'screensize'),'menu','figure','toolbar','figure','Visible','off','renderer','OpenGL');


% modify tool bar
temp= findall(findall(H.f1,'Type','uitoolbar'));
%    ' 1'     'FigureToolBar'
%     ' 2'    'Plottools.PlottoolsOn'
%     ' 3'    'Plottools.PlottoolsOff'
%     ' 4'    'Annotation.InsertLegend'
%     ' 5'    'Annotation.InsertColorbar'
%     ' 6'    'DataManager.Linking'
%     ' 7'    'Exploration.Brushing'
%     ' 8'    'Exploration.DataCursor'
%     ' 9'    'Exploration.Rotate'
%     '10'    'Exploration.Pan'
%     '11'    'Exploration.ZoomOut'
%     '12'    'Exploration.ZoomIn'
%     '13'    'Standard.EditPlot'
%     '14'    'Standard.PrintFigure'
%     '15'    'Standard.SaveFigure'
%     '16'    'Standard.FileOpen'
%     '17'    'Standard.NewFigure'
%     '18'    ''

set(temp(15),'ClickedCallback',@Saveresults,'TooltipString','Save resutls')



delete(temp([2:7 9 13 17]));
uipushtool(temp(1),'Tag','Reload image from file','Cdata',imread('reload.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','Reload image from file',...
    'HandleVisibility','on','ClickedCallback',@Load_Image);

uipushtool(temp(1),'Tag','View and edit image file','Cdata',imread('imtool.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','View info and edit image with imtool',...
    'HandleVisibility','on','ClickedCallback',@viewimage);

temp= findall(findall(H.f1,'Type','uitoolbar'));
set(temp(end),'ClickedCallback',@Browse_and_Load)

% Reorder tools
set(temp(1),'Children',[temp(4:end-2);temp(2:3);temp(end)])

uipushtool(temp(1),'Tag','Load existing analysis','Cdata',imread('load_analysis.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','Load existing analysis from file',...
    'HandleVisibility','on','ClickedCallback',@load_analysis);

% add some tools
uipushtool(temp(1),'Tag','Show whole seismogram','Cdata',imread('whole_seismogram.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','Show whole seismogram',...
    'HandleVisibility','on','ClickedCallback',@zoom2seismogram);

uipushtool(temp(1),'Tag','Crop Image','Cdata',imread('crop.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','Crop image',...
    'HandleVisibility','on','ClickedCallback',@crop_image);
uipushtool(temp(1),'Tag','Adjust contrast','Cdata',imread('contrast-icon.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','Adjust contrast',...
    'HandleVisibility','on','ClickedCallback',@adjust_contrast);

uipushtool(temp(1),'Tag','Remove background','Cdata',imread('Removebackground.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','Click remove lare background stains-colorization',...
    'HandleVisibility','on','ClickedCallback',@remove_background_withGAUSSFILT);

% Create button image & Button
tempim=imnoise(zeros([16,16,3],'uint8'),'salt & pepper',0.2);
for ii=2:16, tempim(ii-1:ii,ii-1:ii,1)=255; tempim(ii-1:ii,ii-1:ii,2:3)=0 ;tempim([ii-1:ii],17-[ii-1:ii],1)=255; tempim([ii-1:ii],17-[ii-1:ii],2:3)=0; end
uipushtool(temp(1),'Cdata',tempim,...
    'Separator','off','TooltipString','Remove salt & pepper noise',...
    'HandleVisibility','on','Enable','on','ClickedCallback',@remove_SaltandPepper);

uipushtool(temp(1),'Tag','Correct rotation','Cdata',imread('correct_rotation.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','Cprrect for rotation',...
    'HandleVisibility','on','ClickedCallback',@estimate_rotation);
uipushtool(temp(1),'Tag','Remove Region','Cdata',imread('removeS.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','Draw a region to remove',...
    'HandleVisibility','on','ClickedCallback',@remove_region);
uipushtool(temp(1),'Tag','Undo last','Cdata',imread('undo.jpeg'),...
    'Separator','on','TooltipString','Undo last action',...
    'HandleVisibility','on','Enable','off','ClickedCallback',@Undo_remove);
uipushtool(temp(1),'Tag','Measure tick length','Cdata',imread('tick_length.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','Measure tick length',...
    'HandleVisibility','on','ClickedCallback',@meassure_pix_dist0);
% Image complement
polarity_ic=zeros([16,16,3]); for i=1:16, polarity_ic(1:i,i:16,:)=1;end
uipushtool(temp(1),'Tag','Measure tick length','Cdata',polarity_ic,...
    'Separator','on','TooltipString','Click to change image polarity',...
    'HandleVisibility','on','ClickedCallback',@change_I0_polarity);
clear polarity_ic;


% Time marks up or down
icon_m=zeros([16,16,3]); icon_m(8,:,:)=1; icon_m(4,6:10,:)=1; icon_m(13,6:10,1)=1;
H.timemarkpos=uitoggletool(temp(1),'Tag','Time marks relative position','Cdata',icon_m,...
    'Separator','on','TooltipString','Click to indicate that time mark offset occurs downward',...
    'HandleVisibility','on', 'State','off');
clear icon_m

H.tbar=findall(findall(H.f1,'Type','uitoolbar'));
H.tbar_UNDO=findobj(temp(1),'Tag','Undo last');





H.textfilename=uicontrol('Style', 'text','Parent',H.f1,'units','normalized',...
    'String', 'seismogram file','Position', [0.2 0.96 0.502 0.04],'BackgroundColor',[1 1 1]);
H.CursorPosText=uicontrol('Style', 'text','Parent',H.f1,'units','normalized',...
    'String', 'Cursor coordinates','Position', [0.7 0.95 0.2 0.04],'BackgroundColor',[1 1 1],...
    'FontSize',14);

H.ax1=axes('Units','Normalized','Position',[0.12 0.21 0.802 0.72],...
    'Xtick',[],'Ytick',[],'box','on','Parent',H.f1,'Xaxislocation','Top','CLimMode','manual','Clim',[0 255]);
H.ax2=axes('Units','Normalized','Position',[0.925 0.21 0.07 0.72],...
    'Xtick',[],'Ytick',[],'box','on','Parent',H.f1,'Ydir','Reverse');
H.ax3=axes('Units','Normalized','Position',[0.12 0.08 0.802 0.12],...
    'Xtick',[],'Ytick',[],'box','on','Parent',H.f1);
H.axwait=axes('Units','Normalized','Position',[0.905 0.03 0.11 0.11],'Parent',H.f1,'box', 'off','visible','off');
%pie(H.axwait,[0.99 0.01],{'','1234567'})%,

H.output_mess=uicontrol('Style', 'listbox','Parent',H.f1,'units','normalized',...
    'String', 'Output messages','Position', [0.12 0.001 0.802 0.07]);


% advanced link axes
hlink1 = linkprop([H.ax2 H.ax1],'ylim');
% Store link object on first subplot axes
setappdata(H.ax2,'graphics_linkprop',hlink1);
% advanced link axes
hlink2 = linkprop([H.ax3 H.ax1],'xlim');
% Store link object on first subplot axes
setappdata(H.ax3,'graphics_linkprop',hlink2);


H.hp1 = uipanel('Title','Reference time',...
    'BackgroundColor','white',...
    'Position',[.001 .78 .08 .22],'Parent',H.f1);

H.edit_t0=uicontrol('Style', 'pushbutton','Parent',H.hp1,'units','normalized',...
    'TooltipString','Date & Time of the 1st reference time mark (seismogram with time marks), or of the begining of the 1st trace (seismigram without time marks)',...
    'string', 'yyyymmdd HH:MM:SS','Position',[0.02 0.72 0.96 0.19],...
    'BackgroundColor',[1 1 1],'Callback',@Get_DATE_TIME);

uicontrol('Style', 'Text','Parent',H.hp1,'units','normalized',...
    'String','# of time ticks',...
    'Position',[0.01 0.48 0.5 0.19],'BackgroundColor',[1 1 1]);
H.edit_num_of_ticks=uicontrol('Style', 'edit','Parent',H.hp1,'units','normalized',...
    'TooltipString','Number of time ticks between 1st and last (including 1st and last)',...
    'string','','Position',[0.65 0.5 0.3 0.19],'BackgroundColor',[1 1 1]);

H.mark_1st=uicontrol('Style', 'pushbutton','Parent',H.hp1,'units','normalized',...
    'Tooltip','Mark the ending pixels of the 1st time marks',...
    'String', '1st mark','Position',[0.02 0.28 0.6 0.19],...
    'Callback',@(h,e) mark_1st_and_last(h,e,'FIRST',false));
H.edit_mark_1st=uicontrol('Style', 'pushbutton','Parent',H.hp1,'units','normalized',...
    'Tooltip','Edit the ending pixels of the 1st time marks',...
    'String', 'Edit','Position',[0.63 0.28 0.34 0.19],...
    'Callback',@(h,e) mark_1st_and_last(h,e,'FIRST',true),'Enable','off');

H.mark_last=uicontrol('Style', 'pushbutton','Parent',H.hp1,'units','normalized',...
    'Tooltip','Mark the last pixel of the last time marks',...
    'String', 'Last mark','Position', [0.02 0.05 0.6 0.19],...
    'Callback',@(h,e) mark_1st_and_last(h,e,'LAST',false));
H.edit_mark_last=uicontrol('Style', 'pushbutton','Parent',H.hp1,'units','normalized',...
    'Tooltip','Edit ending pixels of the last time marks',...
    'String', 'Edit','Position', [0.63 0.05 0.34 0.19],...
    'Callback',@(h,e) mark_1st_and_last(h,e,'LAST',true),'Enable','off');


H.mark_start=uicontrol('Style', 'pushbutton','Parent',H.f1,'units','normalized',...
    'String', 'Start of traces','Position', [0.002 0.73 0.05 0.04],...
    'Callback',@(h,e) mark_start(h,e,0));
H.pbedit_start=uicontrol('Style', 'pushbutton','Parent',H.f1,'units','normalized',...
    'String', 'Edit','Position', [0.052 0.73 0.028 0.04],...
    'Callback',@(h,e) mark_start(h,e,1),'Enable','off');
H.mark_end=uicontrol('Style', 'pushbutton','Parent',H.f1,'units','normalized',...
    'String', 'End of traces','Position', [0.002 0.69 0.05 0.04],...
    'Callback',@(h,e) mark_end(h,e,0));
H.pbedit_end=uicontrol('Style', 'pushbutton','Parent',H.f1,'units','normalized',...
    'String', 'Edit','Position', [0.052 0.69 0.028 0.04],...
    'Callback',@(h,e) mark_end(h,e,1),'Enable','off');



H.togle_timebounds_visibility=uicontrol('Style', 'checkbox','Parent',H.f1,'units','normalized',...
    'String', 'Time boundaries visible','Enable','on','BackgroundColor','w',...
    'Position', [0.002 0.65 0.08 0.03],'Callback',@togle_timebounds_visibility);

% H.togle_time_marks=uicontrol('Style', 'checkbox','Parent',H.f1,'units','normalized',...
%     'String', 'Timing symbols visible','Enable','on','BackgroundColor','w',...
%     'Position', [0.002 0.62 0.08 0.03],'Callback',@togle_timesymbols_visibility);



%DT
H.edit_DT=uicontrol('Style', 'edit','Parent',H.f1,'units','normalized',...
    'TooltipString','Time difference between timemarks (s)','String','60',...
    'Position',[0.002 0.59 0.038 0.035],'BackgroundColor',[1 1 1],'Enable','on');
H.edit_DTtrace=uicontrol('Style', 'edit','Parent',H.f1,'units','normalized',...
    'TooltipString','time difference between succeding traces (in hours)','String','1',...
    'Position',[0.044 0.59 0.038 0.035],'BackgroundColor',[1 1 1],'Enable','on');

H.edit_DP=uicontrol('Style', 'edit','Parent',H.f1,'units','normalized',...
    'TooltipString','pixel dist between timemarks (px)','String', '',...
    'Position',[0.002 0.55 0.038 0.035],'BackgroundColor',[1 1 1],'Enable','on');
H.edit_tick_xlength=uicontrol('Style', 'edit','Parent',H.f1,'units','normalized',...
    'TooltipString','Approximate time mark length (px)','String', '25',...
    'Position',[0.044 0.55 0.038 0.035],'BackgroundColor',[1 1 1],...
    'Callback',@Evaluate_ticklength_input);

H.auto_num_of_traces=uicontrol('Style', 'pushbutton','Parent',H.f1,'units','normalized',...
    'String', {'Identify traces', '& timemarks'},'Position', [0.002 0.505 0.08 0.04],...
    'Callback',@find_traces,'Enable','off');
H.adjust_traces=uicontrol('Style', 'pushbutton','Parent',H.f1,'units','normalized',...
    'String', 'Adjust traces','Position', [0.002 0.465 0.08 0.04],'Callback',@adjust_traces);

H.togle_traces_visibility=uicontrol('Style', 'checkbox','Parent',H.f1,'units','normalized',...
    'String', 'Traces 0-line visible','Enable','off','Position', [0.002 0.435 0.08 0.03],...
    'BackgroundColor','w','Callback',@traces_visibility);
H.togle_digital_traces_visibility=uicontrol('Style', 'checkbox','Parent',H.f1,'units','normalized',...
    'String', 'Digitized traces visible','Enable','on','Position', [0.002 0.412 0.08 0.03],...
    'BackgroundColor','w','Callback',@digital_traces_visibility);
H.togle_digital_traces_STD_visibility=uicontrol('Style', 'checkbox','Parent',H.f1,'units','normalized',...
    'String', 'Digitized traces std visible','Enable','on','Position', [0.002 0.39 0.08 0.03],...
    'BackgroundColor','w','Callback',@digital_traces_visibility);




H.correct_classification=uicontrol('Style', 'pushbutton','Parent',H.f1,'units','normalized',...
    'String', 'Edit classification','Position', [0.002 0.32 0.08 0.04],...
    'Callback',@correct_classification,'Enable','off');

H.Create_Time=uicontrol('Style', 'pushbutton','Parent',H.f1,'units','normalized',...
    'String', 'Calculate Timing','Position', [0.002 0.27 0.08 0.04],'Callback',@Create_Time,'Enable','on');

H.text_luminance=uicontrol('Style', 'text','Parent',H.f1,'units','normalized',...
    'String',{'Intensity';'threshold'},'Position', [0.002 0.2 0.04 0.04],'BackgroundColor',[1 1 1]);
H.edit_luminance=uicontrol('Style', 'edit','Parent',H.f1,'units','normalized',...
    'TooltipString','Luminance thershold should be between 1 and 99',...
    'String','10','Position', [0.042 0.2 0.04 0.04],'BackgroundColor',[1 1 1]);
H.text_offset=uicontrol('Style', 'text','Parent',H.f1,'units','normalized',...
    'String',{'Offset from trace';'to digitize'},'Position', [0.002 0.151 0.04 0.04],...
    'BackgroundColor',[1 1 1]);
H.edit_offset=uicontrol('Style', 'edit','Parent',H.f1,'units','normalized',...
    'TooltipString',...
    'Offset bellow and over the trace as a portion of the average trace distance, typical value: [0.3 0.3]',...
    'String','[-0.3 0.3]',...
    'Position', [0.042 0.151 0.04 0.04],'BackgroundColor',[1 1 1]);
H.digitize=uicontrol('Style', 'pushbutton','Parent',H.f1,'units','normalized',...
    'String', 'Digitize','Position', [0.002 0.1 0.08 0.05],'Callback',@digitize_traces,'Enable','Off');

H.digitize_1=uicontrol('Style', 'pushbutton','Parent',H.f1,'units','normalized',...
    'String', 'Correct trace','Position', [0.002 0.048 0.08 0.05],'Callback',@correct_trace);


H.strMousePos=uicontrol('Style', 'pushbutton','Parent',H.f1,'units','normalized',...
    'String', '','FontSize',11,'Tooltip','Push to reset','Position', [0.002 0.002 0.08 0.04],'Callback',set (H.f1, 'WindowButtonMotionFcn', @mouseMove));

set (H.f1, 'WindowButtonMotionFcn', @mouseMove); % Display continiously mouse location
set(H.f1,'Visible','on')



end


function change_I0_polarity(hObject, eventdata)
global I0
I0=imcomplement(I0);
update_plot_image;
end





function Reset_MouseMotionMon(hObject, eventdata)
global H
set (H.f1, 'WindowButtonMotionFcn', @mouseMove); % Display continiously mouse location
end

function mouseMove (object, eventdata)
global H
try
    C = get(H.ax1, 'CurrentPoint');
    set(H.strMousePos,'String',['(X,Y) = (', num2str(C(1,1),'%6.0f'), ', ',num2str(C(1,2),'%6.0f'), ')']);
    set(H.CursorPosText,'String',['(X,Y) = (', num2str(C(1,1),'%6.0f'), ', ',num2str(C(1,2),'%6.0f'), ')']);
end
end



function Get_DATE_TIME(hObject, eventdata)
ho=hObject;
hfc=uicalendar('Weekend', [1 0 0 0 0 0 1],'SelectionType', 1,...
    'WindowStyle','Modal','OutputDateFormat','yyyymmdd');
set(hfc,'Name','Select date and time');
delete(findobj(hfc,'String','Clear all'))
outtime=datestr(now,'HH:MM:SS');
he=uicontrol('Style', 'edit','Parent',hfc,'units','normalized','BackgroundColor',[1 1 1],...
    'String',outtime,'Position',[0.03 0.027 0.4 0.09]);
set(findobj(hfc,'String','OK'),'Callback',@getoutput)
waitfor(hfc);


    function getoutput(hObject, eventdata)
        sd=getappdata(hfc,'selectedSquares');
        outdate = datestr([fliplr(sd.date) sd.day{1} 0 0 0],'yyyymmdd');
        outtime= get(he,'String');
        set(ho,'string',[outdate ' ' outtime])
        close(hfc);
    end
end




function Evaluate_ticklength_input(hObject, eventdata)
global H
if isnan(str2double(get(H.edit_tick_xlength,'String')))
    set(H.auto_num_of_traces,'Enable','off');
else
    set(H.auto_num_of_traces,'Enable','on');
    if str2double(get(H.edit_tick_xlength,'String'))<0
        set(H.mark_1st,'Enable','off')
        set(H.edit_mark_1st,'Enable','off')
        set(H.mark_last,'Enable','off')
        set(H.edit_mark_last,'Enable','off')
    else
        set(H.mark_1st,'Enable','on')
        set(H.edit_mark_1st,'Enable','on')
        set(H.mark_last,'Enable','on')
        set(H.edit_mark_last,'Enable','on')
    end
    
end

end




function Browse_and_Load(hObject,eventdata)
global H

[filename, pathname]=uigetfile({'*.jpg;*.tif;*.png;*.gif','All Image Files';...
    '*.*','All Files' },'Select seismogram');
if isequal(filename,0)
    return
end
set(H.textfilename,'String',filename,'Userdata',pathname)

Load_Image;
end


function Load_Image(hObject, eventdata)
global H I0 pt_traces pt_traceLABEL output_message HIM p_tick_1st p_tick_last pt_start_time pt_end_time

ffile=fullfile(get(H.textfilename,'Userdata'),get(H.textfilename,'string'));
set(H.f1,'Name', ['DigitizeSeis: ' ffile])


[~,~,ext] = fileparts(ffile);
if strcmpi(ext,'.MAT') % is already I0
    load(ffile,'I0');
else
    output_message{end+1}=['Reading image from file: ' ffile ,[' please wait...']];
    set(H.output_mess,'String',output_message,'Value',length(output_message)); drawnow;
    I0=imread(ffile);
    % Adjust histogram to improve contrast
    output_message{end+1}='Converting to 8-bit, HSV, please wait...';
    set(H.output_mess,'String',output_message,'Value',length(output_message));drawnow;
    %check if it is already 1 channel (e.g., b&w)
    if size(I0,3)==3
        I0=im2uint8(rgb2hsv_fast(I0,'Single','V'));
    else
        I0=im2uint8(I0);
    end
    
    button=[];button = questdlg('Press Yes to consider the complement of the scanned image','Image polarity','Yes','No','Yes');
    if strcmp(button,'Yes')
        output_message{end}='Converting to 8-bit, HSV, complement, please wait...';
        set(H.output_mess,'String',output_message,'Value',length(output_message));drawnow;
        I0= imcomplement(I0);
    end
    
    button=[];button = questdlg('Press Yes automatically adsust image histogram','Image Histogram Adjustment','Yes','No','Yes');
    if strcmp(button,'Yes')
        output_message{end}='Converting to 8-bit, HSV, complement, adjusting histogram, please wait...';
        set(H.output_mess,'String',output_message,'Value',length(output_message));drawnow;
        I0=imadjust(I0);
        
    end
end


cla([H.ax1, H.ax2, H.ax3])

try delete(pt_traces); end
try delete(p_tick_1st); end
try delete(p_tick_last); end
try delete(pt_start_time); end
try delete(pt_end_time); end
try delete(pt_traces); end
try delete(pt_traceLABEL); end




% HIM=image(I0,'Parent',H.ax1);
%HIM=imagesc(I0,'Parent',H.ax1,'AlphaDataMapping','None','CDataMapping','direct');  colormap(H.ax1,gray(256);
HIM=image(I0,'Parent',H.ax1); colormap(H.ax1,gray(256));
set(H.ax1,'Xaxislocation','Top','CLimMode','manual','Clim',[0 255])
drawnow

% % put 1st and last tickmark at null positions
% hold(H.ax1,'on')
% p_tick_1st=plot(H.ax1,0,0,'gv','MarkerSize',20);set(p_tick_1st,'Visible','off');
% p_tick_last=plot(H.ax1,0,0,'r^','MarkerSize',20);set(p_tick_last,'Visible','off');
% hold(H.ax1,'off')
% set([p_tick_1st,p_tick_last],'Visible','off')

output_message{end+1}='Ready.';
set(H.output_mess,'String',output_message,'Value',length(output_message));drawnow;
end




function update_plot_image(hObject, eventdata)
global H I0 HIM
xyl=axis(H.ax1);
set(HIM,'Cdata',I0)
axis(H.ax1,xyl);
%title(H.ax1,get(H.textfilename,'string'),'Interpreter','none')
%set(H.ax1,'Xaxislocation','Top')
drawnow;
end


function zoom2seismogram(hObject, eventdata)
global I0 H
set(H.ax1,'Xlim',[1 size(I0,2)],'Ylim',[1,size(I0,1)],'Xaxislocation','Top')
drawnow;
Reset_MouseMotionMon;
end


function adjust_contrast(hObject, eventdata)
global H I0 Iundo
Iundo=I0;
hFig = figure('Color','w','Toolbar','none','NumberTitle','off',...
    'Menubar','none','Visible','off','closerequestfcn','','Name',H.textfilename.String);
hIm = imshow(I0);
hSP = imscrollpanel(hFig,hIm);
set(hSP,'Units','normalized',...
    'Position',[0.0 0.05 1 .95])
hMagBox = immagbox(hFig,hIm);
pos = get(hMagBox,'Position');
set(hMagBox,'Position',[0 0 pos(3) pos(4)])
%imoverview(hIm0);
hImCon=imcontrast(hIm);
set(hFig,'Visible','on')
waitfor(hImCon);
I0=get(hIm,'Cdata');
update_plot_image;
delete(hFig);
% enable undo
set(H.tbar_UNDO,'Enable','on');
end


function remove_SaltandPepper(hObject,eventdata)
global I0 Iundo H

Fig_remove_SaltandPepper = figure('Units','Normalized','Position',[0.1 0.1 0.5 0.7],...
    'color','w','WindowStyle','Normal','NumberTitle','Off','Name','Remove bacground long wavelength noise of the image with Gaussian filtering');

hbg=uibuttongroup('Visible','on','BackgroundColor',[1 1 1],'Position',[0.01 0.01 0.25 0.04],'Title','Filter type');
uicontrol(hbg,'Style','radiobutton','units','normalized',...
    'String', '2-D Median','BackgroundColor',[1 1 1],...
    'Position', [0.05 0.01 0.4 1]);
uicontrol(hbg,'Style','radiobutton','units','normalized',...
    'String', 'Wiener','BackgroundColor',[1 1 1],...
    'Position', [0.55 0.01 0.4 1]);

uicontrol('Style', 'Text','Parent',Fig_remove_SaltandPepper,'units','normalized',...
    'String', 'm x n neighborhood:','BackgroundColor',[1 1 1],...
    'Position', [0.30 0.015 0.08 0.02],'HorizontalAlignment','right');
Mvalue=uicontrol('Style', 'Edit','Parent',Fig_remove_SaltandPepper,'units','normalized','tag','Vsigma',...
    'String', '4','Tooltip','Enter a positive scalar','BackgroundColor',[1 1 1],...
    'Position', [0.39 0.02 0.06 0.02]);
uicontrol('Style', 'Text','Parent',Fig_remove_SaltandPepper,'units','normalized',...
    'String', 'x','BackgroundColor',[1 1 1],...
    'Position', [0.455 0.015 0.01 0.02]);
Nvalue=uicontrol('Style', 'Edit','Parent',Fig_remove_SaltandPepper,'units','normalized','tag','Vsigma',...
    'String', '4','Tooltip','Enter a positive scalar','BackgroundColor',[1 1 1],...
    'Position', [0.468 0.02 0.06 0.02]);

uicontrol('Style', 'pushbutton','Parent',Fig_remove_SaltandPepper,'units','normalized',...
    'String', 'Preview', 'Position',[0.68 0.01 0.09 0.04],'Callback',@PreviewChanges);

uicontrol('Style', 'pushbutton','Parent',Fig_remove_SaltandPepper,'units','normalized',...
    'String', 'Apply','Position', [0.79 0.01 0.09 0.04],'Callback',@ApplyChanges);

uicontrol('Style', 'pushbutton','Parent',Fig_remove_SaltandPepper,'units','normalized',...
    'String', 'Cancel','Position', [0.90 0.01 0.09 0.04],'Callback',@(hObject,eventdata)(close(Fig_remove_background)));


%%
ax1=subplot(2,1,1);
imshow(I0)
ax2=subplot(2,1,2);
Itemp=I0;
HItemp=imshow(Itemp);
ax2.Visible='off';
linkaxes([ax1,ax2])
waitfor(Fig_remove_SaltandPepper)
clear Itemp;


    function PreviewChanges(hObject_l,eventdata_l)
        mn=[str2double(get(Mvalue,'String')) str2double(get(Nvalue,'String'))];
        if strcmp(get(hbg,'SelectedObject'),'Wiener')
            Itemp=wiener2(I0,mn);
        else
            Itemp=medfilt2(I0,mn);
        end
        set(HItemp,'CData',Itemp);
        drawnow;
        disp('ok')
    end

    function ApplyChanges(hObject_l,eventdata_l)
        PreviewChanges;
        Iundo=I0;
        I0=Itemp;
        update_plot_image;
        delete(Fig_remove_SaltandPepper);
        set(H.tbar_UNDO,'Enable','on');
        
    end

end




function remove_background_withGAUSSFILT(hObject,eventdata)
global I0 Iundo H

Fig_remove_background = figure('Units','Normalized','Position',[0.1 0.1 0.5 0.7],...
    'color','w','WindowStyle','Normal','NumberTitle','Off','Name','Remove bacground long wavelength noise of the image with Gaussian filtering');

uicontrol('Style', 'Text','Parent',Fig_remove_background,'units','normalized',...
    'String', 'Gaussian distribution standard deviation,','BackgroundColor',[1 1 1],...
    'Position', [0.001 0.02 0.31 0.03]);

uicontrol('Style', 'Text','Parent',Fig_remove_background,'units','normalized',...
    'String', 'Vertical:','BackgroundColor',[1 1 1],...
    'Position', [0.32 0.02 0.08 0.03]);


Vsigma=uicontrol('Style', 'Edit','Parent',Fig_remove_background,'units','normalized','tag','Vsigma',...
    'String', '','Tooltip','Enter a positive scalar','BackgroundColor',[1 1 1],...
    'Position', [0.4 0.02 0.04 0.03]);
uicontrol('Style', 'Text','Parent',Fig_remove_background,'units','normalized',...
    'String', 'Horizontal:','BackgroundColor',[1 1 1],...
    'Position', [0.47 0.02 0.08 0.03]);
Hsigma=uicontrol('Style', 'Edit','Parent',Fig_remove_background,'units','normalized','tag','Hsigma',...
    'String', '','Tooltip','Enter a positive scalar','BackgroundColor',[1 1 1],...
    'Position', [0.56 0.02 0.04 0.03]);

uicontrol('Style', 'pushbutton','Parent',Fig_remove_background,'units','normalized',...
    'String', 'Preview', 'Position',[0.68 0.01 0.09 0.04],'Callback',@PreviewChanges);

uicontrol('Style', 'pushbutton','Parent',Fig_remove_background,'units','normalized',...
    'String', 'Apply','Position', [0.79 0.01 0.09 0.04],'Callback',@ApplyChanges);

uicontrol('Style', 'pushbutton','Parent',Fig_remove_background,'units','normalized',...
    'String', 'Cancel','Position', [0.90 0.01 0.09 0.04],'Callback',@(hObject,eventdata)(close(Fig_remove_background)));


ax1=subplot(2,1,1);
imshow(I0)
ax2=subplot(2,1,2);
Itemp=I0;
HItemp=imshow(Itemp);
ax2.Visible='off';
linkaxes([ax1,ax2])
waitfor(Fig_remove_background)
clear Itemp;


    function PreviewChanges(hObject_l,eventdata_l)
        sig=[str2double(get(Vsigma,'String')) str2double(get(Hsigma,'String'))];
        Itemp=imadjust(imsubtract(I0,imgaussfilt(I0,sig)));
        set(HItemp,'CData',Itemp);
    end

    function ApplyChanges(hObject_l,eventdata_l)
        
        PreviewChanges;
        Iundo=I0;
        I0=Itemp;
        update_plot_image;
        delete(Fig_remove_background);
        set(H.tbar_UNDO,'Enable','on');
        
    end

end





function meassure_pix_dist0(hObject, eventdata)
global H
hd0 = imline(H.ax1);
setColor(hd0,[1 1 0]);
pos=getPosition(hd0);
ht0=text('position',mean(pos),'string',num2str(round(abs(pos(2,1)- pos(1,1)))),'backgroundColor',[.9 .9 .8]);
addNewPositionCallback(hd0,@(pos)show_xdist(pos));
pos=wait(hd0);
delete(hd0);
% set(H.edit_tick_xlength,'String',num2str(round(abs(pos(2,1)- pos(1,1)))))

    function show_xdist(pos)
        set(ht0,'position',mean(pos),'string',num2str(round(abs(pos(2,1)- pos(1,1)))),'backgroundColor',[.9 .9 .8])
    end
delete(ht0);

% Evaluate_ticklength_input;


end

function remove_region(hObject, eventdata)
global H Iundo I0
Iundo=I0; % save an undo copy
h=imfreehand(H.ax1);
h.Deletable = false;
try
    I0(h.createMask)=0;
    delete(h);
catch
    delete(h);
    return
end
update_plot_image;
set(H.tbar_UNDO,'Enable','on');
end

function Undo_remove(hObject, eventdata)
global H Iundo I0
I0=Iundo;
clear Iundo;
set(H.tbar_UNDO,'Enable','off');
update_plot_image;
end


function viewimage(hObject, eventdata)
global H I0
ffile=fullfile(get(H.textfilename,'Userdata'),get(H.textfilename,'string'));
imtool(I0);
end

%
function crop_image(hObject, eventdata)
global H I0 Iundo
%h=figure('Menu','none','Toolbar','none');%'WindowStyle','Modal');
temp=imcrop(H.ax1);
if isempty(temp)
    return
end
Iundo=I0;
I0=temp;
axis(H.ax1,[1,size(I0,2),1,size(I0,1)]);
set(H.tbar_UNDO,'Enable','on');
update_plot_image;
end


function estimate_rotation(hObject, eventdata)
global H Iundo I0 output_message
Iundo=I0;
% Take radon transform for +- 5 degrees with the horizontal

output_message{end+1}='Searching for optimum rotation... ';
set(H.output_mess,'String',output_message,'Value',length(output_message)); drawnow;

theta0=[82:1:98];
R=zeros(size(theta0));
for i=1:numel(theta0)
    
    output_message{end}=['Testing... ' num2str(theta0(i)-90) ' degrees'];
    set(H.output_mess,'String',output_message,'Value',length(output_message));
    R(i)=min(sum(imrotate(I0,theta0(i),'bilinear','crop'),2));
end
[~,idx]=min(R);
ang0=theta0(idx)-90;

%refine search
output_message{end}='Refining search around mimimum';
set(H.output_mess,'String',output_message,'Value',length(output_message));


theta=[theta0(idx)-1.1:0.1:theta0(idx)+1.1];
RR=zeros(size(theta));
for i=1:numel(theta)
    output_message{end}=['Testing... ' num2str(theta(i)-90) ' degrees'];
    set(H.output_mess,'String',output_message,'Value',length(output_message));
    
    RR(i)=min(sum(imrotate(I0,theta(i),'bilinear','crop'),2));
end
[~,idx]=min(RR);
ang=theta(idx)-90;

hf=figure('WindowStyle','modal','Color','w','Name','Estimate Rotation','NumberTitle','off');
subplot(211)
plot(theta0-90,R,'k'), hold on
plot([ang0 ang0],get(gca,'ylim'),'r');
title(['Initial Estimation: ' num2str(ang0,'%3.2f') '^o'])
ylabel('Min(sum(intensity))')

subplot(212)
plot(theta-90,RR,'k'), hold on
plot([ang ang],get(gca,'ylim'),'r');
axis tight
xlabel('Rotation from horizontal (degrees)'),ylabel('Min(sum(intensity))')
title(['Refined Estimation: ' num2str(ang,'%3.2f') '^o'])
output_message{end}=['Rotation estimation: ' num2str(ang,'%3.2f') ' degrees'];
set(H.output_mess,'String',output_message,'Value',length(output_message));
uiwait(gcf)

%% Rotate Image
rot_ang = inputdlg('Rotate image','Enter rotation angle',1,{num2str(ang)});
if isempty(rot_ang)
    return
end
rot_ang = str2num(rot_ang{1});

if abs(rot_ang)<0.01
    warndlg('Angle is negligible','No rotation applied')
    return
end
% Rotate image accordingly
I0=imrotate(I0,rot_ang,'bilinear','crop');

output_message{end+1}=['Image rotated: ' num2str(rot_ang,'%3.2f') '^o.'];
set(H.output_mess,'String',output_message,'Value',length(output_message)); drawnow;
set(H.tbar_UNDO,'Enable','on')


update_plot_image;
end





function find_traces(hObject, eventdata)
global H I0 ftrend sumI ww pt_start_time pt_end_time pt_traces pt_traceLABEL output_message

output_message{end+1}='Detecting traces, please wait...';
set(H.output_mess,'String',output_message,'Value',length(output_message)); drawnow;


% DEBUG MODE --> COMMENT
% try delete(pt_start_time); end
% try delete(pt_end_time); end
% pt_start_time=[];
% pt_end_time=[];


num_of_v_divisions=10;
[rows, cols]=size(I0);

ww=zeros(num_of_v_divisions,2);
d=ceil(cols/num_of_v_divisions);
sumI=zeros(rows,num_of_v_divisions);
for it=1:num_of_v_divisions
    win=max(1,floor((it-1)*d-d/3)):min(cols,ceil(it*d+d/3));
    sumI(:,it)=sum(I0(:,win),2);
    sumI(:,it)=sumI(:,it)/max(sumI(:,it));
    ww(it,:)=[win(1) win(end)];
end

hold(H.ax2, 'off')
%hold(H.ax1,'on')
%cm=jet(10);
imagesc(linspace(1,cols,size(sumI,2)),linspace(1,rows,size(sumI,1)),sumI,'Parent',H.ax2)
hold(H.ax2,'on')
% for it=1:num_of_v_divisions
% %    plot(H.ax1,mean(ww(it,:))+0.3*d*sumI(:,it),[1:rows]','color',cm(it,:))
%     plot(H.ax2,mean(ww(it,:))+1.5*d*sumI(:,it),[1:rows]')
%     hold(H.ax2,'on')
% end
%axis(H.ax2,'tight')
set(H.ax2,'yticklabel','','ylim',[1 size(I0,1)],'Ydir','Reverse');

%cross-correlate and find trend
maxlags=round(rows/3);
shift=zeros(1,num_of_v_divisions-1);
imaxc=zeros(1,num_of_v_divisions-1);
for it=2:num_of_v_divisions
    [c_ww{it-1},lags{it-1}] = xcorr(sumI(:,it-1),sumI(:,it),maxlags,'coeff');
    [~,imaxc(it-1)]=max(c_ww{it-1});
    shift(it-1)=lags{it-1}(imaxc(it-1));
end
ftrend = fit( mean(ww,2), [0, -cumsum(shift)]', 'poly2');
%plot(H.ax1,1:cols,rows/2+ftrend(1:cols),'m--','LineWidth',4);
plot(H.ax2,1:cols,rows/2+ftrend(1:cols),'-','LineWidth',4,'Color',[0. 0.7 1]);


tol=0.2;
lenpks=zeros(num_of_v_divisions,1);
for it=1:num_of_v_divisions
    [pks{it}, locs{it}]=findpeaks(smooth(sumI(:,it),round(rows/220)),'MinPeakHeight',tol);
    lenpks(it)=numel(pks{it});
end

numpeaks=mode(lenpks); % find dominant (most frequent) number
try delete(pt_traces), end
try delete(pt_traceLABEL), end


iok=1;
for i=1:length(locs)
    if length(locs{i})==numpeaks
        iok=i;
        break
    end
    
end
locs=locs{iok};

pt_traces=zeros(numpeaks,1);
pt_traceLABEL=zeros(numpeaks,1);
%std_lenpks=std(lenpks);
hold(H.ax1,'on')
for i=1:numpeaks
    pt_traces(i)=plot(H.ax1,1:cols,locs(i)+ftrend(1:cols)-ftrend(1),'c--','LineWidth',1);
    pt_traceLABEL(i)=text(100,locs(i)+ftrend(100)-ftrend(1),num2str(i),'BackgroundColor',[1 1 .8],'Parent',H.ax1);
end
hold(H.ax1,'off')

%return % DEBUG MODE --> COMMENT in normal mode



find_tickmarks;




set(H.togle_traces_visibility,'Enable','on','value',1)
set(H.digitize,'Enable','on')


output_message{end+1}='Ready';
set(H.output_mess,'String',output_message,'Value',length(output_message)); drawnow;
end


function traces_visibility(hObject, eventdata)
global H pt_traces pt_traceLABEL
try
    if get(H.togle_traces_visibility,'value')
        set([pt_traces; pt_traceLABEL],'visible','on')
    else
        set([pt_traces; pt_traceLABEL],'visible','off')
    end
catch
    pt_traces=flipud(findobj(H.ax1,'Color','c','Linestyle','--'));
    pt_traceLABEL=flipud(findobj(H.ax1,'type','text','FontSize',10,'BackgroundColor',[1 1 0.800]));
    if get(H.togle_traces_visibility,'value')
        set([pt_traces; pt_traceLABEL],'visible','on')
    else
        set([pt_traces; pt_traceLABEL],'visible','off')
    end
end
end


function digital_traces_visibility(hObject, eventdata)
global H ptrace ptraceSTD % pt_traces

if get(H.togle_digital_traces_visibility,'value')
    set(ptrace,'visible','on')
else
    set(ptrace,'visible','off')
end


try
    if get(H.togle_digital_traces_STD_visibility,'value')
        set(ptraceSTD,'visible','on')
    else
        set(ptraceSTD,'visible','off')
    end
catch
   errordlg('Could not find handles for digitized traces STD. If this file is from an older version of DigitSeis without this feature, ignore this message');
   set(ptraceSTD,'visible','off') 
end


end


function find_tickmarks(hObject, eventdata)
global H I0 Inull ftrend_tick sumInull output_message S BW tick_length_lim
output_message{end+1}='Analysing time marks, please wait...';
set(H.output_mess,'String',output_message,'Value',length(output_message)); drawnow



[rows,cols]=size(I0);
tick_length=str2double(get(H.edit_tick_xlength,'String'));
if isnan(tick_length)
    errordlg('Invalid length of time marks!','Error!')
    return
end


%% debug mode set debbbb=1 to skip recalculating classification
debbbb=false;
if ~debbbb
    % % classify for 1st time.
    level=str2double(get(H.edit_luminance,'String'));
    %BW=im2bw(I0,level);
    BW=im2bw(I0,level/100);
    
    
    prompt = {'Enter the min number of pixels for the objects (connected components) of binary image. Objects with less number of pixels will be removed. press "Cancel" to keep everything'};
    answerP = inputdlg(prompt,'Number of pixels threshold');
    if ~isempty(answerP)
        output_message{end}=sprintf('Removing objects with less than %s pixels',answerP{1});
        set(H.output_mess,'String',output_message,'Value',length(output_message)); drawnow
        BW = bwareaopen(BW,round(str2double(answerP{1}))); %removes all connected components (objects) that have fewer than P pixels
        
    end
    
    
    output_message{end+1}='Classifying binary image...';
    set(H.output_mess,'String',output_message,'Value',length(output_message)); drawnow
    
    
    S=regionprops(BW,{'BoundingBox','PixelIdxList'});
    % add the id field 0 for normal trace, 1 for time mark, -1 for
    % rejected objects
    tmp=cell(size(S)); [S(:).ID]=deal(tmp{:});
    time_length=cell2mat({S.BoundingBox}');
    time_length=time_length(:,3)';% tale width;
    
    
    if tick_length>0
        idTick=abs(time_length-tick_length)<tick_length_lim*tick_length;
        idTrace=time_length-tick_length>tick_length_lim*tick_length;
    else
        idTick=[];
        idTrace=time_length+tick_length>tick_length_lim*(-tick_length);
    end
    
    [S(idTrace).ID]=deal(0);
    [S(idTick).ID]=deal(1);
    idRej=cellfun(@(x) isempty(x),{S.ID});
    [S(idRej).ID]=deal(-1);
    
    Sticks=S(idTick);
    tick_indx=cell2mat({Sticks.PixelIdxList}');
    
    
else % Debug mode no recalculation
    tick_indx=cell2mat({S(find([S.ID]==1)).PixelIdxList}');
end


output_message{end}='Assigning objects to traces ...';
set(H.output_mess,'String',output_message,'Value',length(output_message)); drawnow

Assign_Objects_to_Traces_1stTime();





mask=true(size(I0)); mask(tick_indx)=false;
Inull=I0; Inull(mask)=0;

output_message{end}='Preparing to calculate the trend of time marks...';
set(H.output_mess,'String',output_message,'Value',length(output_message)); drawnow

% find the trend of tickmarks in y axis
[rows, cols]=size(Inull);
num_of_divisions=11;
wwt=zeros(num_of_divisions,2);
d=ceil(rows/num_of_divisions);
sumInull=zeros(num_of_divisions,cols);
for it=1:num_of_divisions
    win=max(1,floor((it-1)*d-d/3)):min(rows,ceil(it*d+d/3));
    sumInull(it,:)=sum(Inull(win,:),1);
    sumInull(it,:)=sumInull(it,:)/max(sumInull(it,:));
    wwt(it,:)=[win(1) win(end)];
end


output_message{end}='Updating figure, please wait...';
set(H.output_mess,'String',output_message,'Value',length(output_message)); drawnow;
hold(H.ax3, 'off')
imagesc(linspace(1,cols,size(sumInull,2)),linspace(1,rows,size(sumInull,1)),sumInull,'Parent',H.ax3)

output_message{end}='Calculating the trend of time marks, please wait...';
set(H.output_mess,'String',output_message,'Value',length(output_message)); drawnow

%cross-correlate and find trend
maxlags=round(cols/50);
lags=cell(1,num_of_divisions-1);
c_ww=cell(1,num_of_divisions-1);
Shift=zeros(1,num_of_divisions-1);
imaxc=zeros(1,num_of_divisions-1);
for it=2:num_of_divisions
    [c_ww{it-1},lags{it-1}] = xcorr(sumInull(it-1,:),sumInull(it,:),maxlags,'coeff');
    [~,imaxc(it-1)]=max(c_ww{it-1});
    Shift(it-1)=lags{it-1}(imaxc(it-1));
end
ftrend_tick = fit( mean(wwt,2), [0, -cumsum(Shift)]', 'linearinterp');
%plot(H.ax1,cols/2+ftrend_tick(1:rows),1:rows,'m--','LineWidth',4);
% plot(H.ax3,cols/2+ftrend_tick(1:rows),1:rows,'-','LineWidth',4,'color',[0.6 0.6 0.6]);
hold(H.ax3,'on')
plot(H.ax3,cols/2+ftrend_tick(1:rows),1:rows,'-','LineWidth',4,'color',[1 0.6 0.6]);
set(H.ax3,'yticklabel','','xticklabel','','xlim',[1 size(I0,2)],'Ydir','reverse');
hold(H.ax3,'off')

output_message{end}='Updating the time marks matrix, please wait...';
set(H.output_mess,'String',output_message,'Value',length(output_message)); drawnow

set(H.correct_classification,'Enable','on')
end




function mark_1st_and_last(hObject, eventdata,typeflag,edit_flag)
global H pt_traces ftrend_tick p_tick_1st p_tick_last
% marks the 1st time mark

if edit_flag
    if strcmpi(typeflag,'FIRST')
        X=get(p_tick_1st,'Xdata');
        Y=get(p_tick_1st,'Ydata');
    elseif strcmpi(typeflag,'LAST')
        X=get(p_tick_last,'Xdata');
        Y=get(p_tick_last,'Ydata');
    else
        error('mark_1st_and_last:Uknown typeflag');
    end
    
else % select with mouse
    [x,~]=ginput(1);
    
    x=round(x);
    ptrX=get(pt_traces,'Xdata');
    ptrY=get(pt_traces,'Ydata');
    
    X=zeros(length(pt_traces),1);
    Y=zeros(length(pt_traces),1);
    
    for i=1:length(pt_traces)
        
        [vmin,imin]=min(abs(ptrX{i}-x));
        if vmin>2 % pixels
            X(i)=nan;
            Y(i)=nan;
        else
            Y(i)=ptrY{i}(imin);
            X(i)=ftrend_tick(Y(i));
        end
    end
    
    temp=X(~isnan(X));
    X=X+x-temp(1);
    
end



if strcmpi(typeflag,'FIRST')
    try  delete(p_tick_1st); end
    set(H.edit_mark_1st,'Enable','on');
else strcmpi(typeflag,'LAST')
    try delete(p_tick_last);  end
    set(H.edit_mark_last,'Enable','on');
end

hpoly=impoly(H.ax1,[X(:),Y(:)],'Closed',false);
hpoly.Deletable = false;
pos=round(wait(hpoly));
delete(hpoly);

hold(H.ax1,'on');
if strcmpi(typeflag,'FIRST')
    p_tick_1st=plot(pos(:,1),pos(:,2),'+-','Color',[0 0.8 0]);
else strcmpi(typeflag,'LAST')
    p_tick_last=plot(pos(:,1),pos(:,2),'+-','Color',[0.8 0 0]);
end
hold(H.ax1,'off');

end








function mark_start(hObject, eventdata,edit_flag)
global H I0 pt_start_time pt_traces
%[t0(1), t0(2)]=ginput(1);
% set(pt_start_time,'Xdata',t0(1),'Ydata',t0(2))
% set(H.text_t0,'String',sprintf('xp=%.0f yp=%.0f',round(t0(1)), round(t0(2))))
% drawnow

if edit_flag
    X=get(pt_start_time,'Xdata');
    Y=get(pt_start_time,'Ydata');
else
    offset=500;
    delete(pt_start_time);
    [x1,~]=ginput(1);
    
    x1=round(x1);
    
    [rows,~]=size(I0);
    
    X=zeros(length(pt_traces),1);
    Y=cell2mat(cellfun(@(v) v(1),get(pt_traces,'Ydata'),'UniformOutput',false));
    for i=1:length(pt_traces)
        [~,X(i)]=max(abs(rangefilt(mean(I0(max(1,round(Y(i))-offset):min(rows,round(Y(i))+offset),1:2*x1)),true(1,7))));
    end
end


delete(pt_start_time);
hpoly=impoly(H.ax1,[X(:),Y(:)],'Closed',false);
hpoly.Deletable = false;
pos=round(wait(hpoly));
delete(hpoly);



% % pt_tracesX=[];
% % pt_tracesY=[];
% % load('to_delete_temp.mat','pt_tracesX','pt_tracesY')
% %
% % pos(:,1)=pt_tracesX; pos(:,2)=pt_tracesY;
% %
hold(H.ax1,'on');
pt_start_time=plot(pos(:,1),pos(:,2),'>g-');
hold(H.ax1,'off');

% % return


for i=1:length(pt_traces)
    X=get(pt_traces(i),'Xdata');
    Y=get(pt_traces(i),'Ydata');
    
    if pos(i,1)>X(1) % truncate
        idok= X>pos(i,1)-1-eps;
        set(pt_traces(i),'Xdata',X(idok),'Ydata',Y(idok));
    elseif pos(i,1)<X(1) % extrapolate
        extrapoints=pos(i,1):X(1)-1;
        set(pt_traces(i),'Xdata',[extrapoints, X],'Ydata',[interp1(X,Y,extrapoints,'linear','extrap'), Y]);
    end
    
end
drawnow;

set(H.pbedit_start,'Enable','on');
set(H.togle_timebounds_visibility,'Enable','on')
togle_timebounds_visibility;
end



function update_start_time()
% This is a function for Debuging mode.
% It updates the pt_traces lengths based on the pt_start_time

global pt_start_time pt_traces
XSTART=get(pt_start_time,'XData');

for i=1:length(pt_traces)
    X=get(pt_traces(i),'Xdata');
    Y=get(pt_traces(i),'Ydata');
    
    if XSTART(i)>X(1) % truncate
        idok= X>XSTART(i)-1-eps;
        set(pt_traces(i),'Xdata',X(idok),'Ydata',Y(idok));
    elseif XSTART(i)<X(1) % extrapolate
        extrapoints=XSTART(i):X(1)-1;
        set(pt_traces(i),'Xdata',[extrapoints, X],'Ydata',[interp1(X,Y,extrapoints,'linear','extrap'), Y]);
    end
    
end
drawnow;

togle_timebounds_visibility;
end

function update_end_time()
% This is a function for Debuging mode.
% It updates the pt_traces lengths based on the pt_start_time

global pt_end_time pt_traces
XEND=get(pt_end_time,'XData');



for i=1:length(pt_traces)
    X=get(pt_traces(i),'Xdata');
    Y=get(pt_traces(i),'Ydata');
    
    if XEND(i)<X(end) % truncate
        idok=X<XEND(i)+eps+1;
        set(pt_traces(i),'Xdata',X(idok),'Ydata',Y(idok));
    elseif XEND(i)>X(end) % extrapolate
        extrapoints=X(end)+1:XEND(i);
        set(pt_traces(i),'Xdata',[X extrapoints],'Ydata',[Y, interp1(X,Y,extrapoints,'linear','extrap')]);
    end
    
    
end
drawnow;

togle_timebounds_visibility;
end



function mark_end(hObject, eventdata,edit_flag)
global H I0 pt_traces pt_end_time

if edit_flag
    X=get(pt_end_time,'Xdata');
    Y=get(pt_end_time,'Ydata');
else
    offset=500;
    [x1,~]=ginput(1);
    x1=round(x1);
    
    [rows,cols]=size(I0);
    
    X=zeros(length(pt_traces),1);
    Y=cell2mat(cellfun(@(v) v(end),get(pt_traces,'Ydata'),'UniformOutput',false));
    
    jstart=round(max(cols/4,3*x1-2*cols)):cols;
    for i=1:length(pt_traces)
        [~,X(i)]=max(abs(rangefilt(mean(...
            I0(max(1,round(Y(i))-offset):min(rows,round(Y(i))+offset),jstart)),true(1,7))));
    end
    X=X+jstart(1)-1;
end


delete(pt_end_time);
hpoly=impoly(H.ax1,[X(:),Y(:)],'Closed',false);
hpoly.Deletable = false;
pos=round(wait(hpoly));
delete(hpoly);

hold(H.ax1,'on');
pt_end_time=plot(pos(:,1),pos(:,2),'<r-');
hold(H.ax1,'off');


for i=1:length(pt_traces)
    X=get(pt_traces(i),'Xdata');
    Y=get(pt_traces(i),'Ydata');
    
    if pos(i,1)<X(end) % truncate
        idok=X<pos(i,1)+eps+1;
        set(pt_traces(i),'Xdata',X(idok),'Ydata',Y(idok));
    elseif pos(i,1)>X(end) % extrapolate
        extrapoints=X(end)+1:pos(i,1);
        set(pt_traces(i),'Xdata',[X extrapoints],'Ydata',[Y, interp1(X,Y,extrapoints,'linear','extrap')]);
    end
    
    
end
drawnow;

set(H.pbedit_end,'Enable','on');
set(H.togle_timebounds_visibility,'Enable','on')
togle_timebounds_visibility;
end


% function togle_timesymbols_visibility(hObject, eventdata)
% global  hresult_time_marks
% try
%     if ishandle(hresult_time_marks)
%
%         if get(hObject,'value')
%             set(hresult_time_marks,'Visible','on')
%         else
%             set(hresult_time_marks,'Visible','off')
%         end
%     end
% end
% end



function togle_timebounds_visibility(hObject, eventdata)
global H pt_start_time pt_end_time p_tick_1st p_tick_last hresult_time_marks

if get(H.togle_timebounds_visibility,'value')
    if ishandle(pt_start_time)
        set(pt_start_time,'visible','on')
    end
    if  ishandle(pt_end_time)
        set(pt_end_time,'visible','on')
    end
    if ishandle(p_tick_1st)
        set(p_tick_1st,'visible','on')
    end
    if ishandle(p_tick_last)
        set(p_tick_last,'visible','on')
    end
    if ishandle(hresult_time_marks)
        set(hresult_time_marks,'visible','on')
    end
    
else
    if ishandle(pt_start_time)
        set(pt_start_time,'visible','off')
    end
    if  ishandle(pt_end_time)
        set(pt_end_time,'visible','off')
    end
    if ishandle(p_tick_1st)
        set(p_tick_1st,'visible','off')
    end
    if ishandle(p_tick_last)
        set(p_tick_last,'visible','off')
    end
    
    if ishandle(hresult_time_marks)
        set(hresult_time_marks,'visible','off')
    end
    
end


end





function  Assign_Objects_to_Traces_1stTime()
global H BW S pt_traces ftrend


over_under=str2num(get(H.edit_offset,'string')); %#ok<ST2NM>
[rows,cols]=size(BW);

fX=ftrend(cell2mat(cellfun(@(v) v(1),get(pt_traces,'Xdata'),'UniformOutput',false)));
Y=cell2mat(cellfun(@(v) v(1),get(pt_traces,'Ydata'),'UniformOutput',false));
meanOffset=mode(abs(diff(Y)));

Bbox=cell2mat({S.BoundingBox}');
itickL=[S.ID]==1;
itraceL=[S.ID]==0;

C=[Bbox(:,2)+Bbox(:,4)/2,Bbox(:,1)+Bbox(:,3)/2, [1:size(Bbox,1)]']; % the last column is just the initial index.
Ctick=C(itickL,:);
C=C(itraceL,:);


[S.TraceNum]=deal(-1);

for i=1:numel(pt_traces)
    
    % prepare stripes
    zerotrace_i= Y(i)-fX(i)+ftrend(C(:,2));
    itrace_i=C(:,1) > over_under(1)*meanOffset+zerotrace_i &...
        C(:,1) < over_under(2)*meanOffset+zerotrace_i;
    zerotick_i=Y(i)-fX(i)+ftrend(Ctick(:,2));
    
    if  strcmpi(get(H.timemarkpos,'State'),'off') % time marks above the trace
        itick_i=Ctick(:,1) > -abs(over_under(1))*meanOffset+zerotick_i-meanOffset/2 &...
            Ctick(:,1) < zerotick_i;
    elseif strcmpi(get(H.timemarkpos,'State'),'on')  % time marks bellow the trace
        itick_i=Ctick(:,1) < abs(over_under(2))*meanOffset+zerotick_i+meanOffset/2 &...
            Ctick(:,1) > zerotick_i;
    end
    
    [S(C(itrace_i,end)).TraceNum]=deal(i);
    [S(Ctick(itick_i,end)).TraceNum]=deal(i);
end

end









%%
function correct_classification(hObject,eventdata)
global H I0 S BW

set (H.f1, 'WindowButtonMotionFcn', []);

level=str2double(get(H.edit_luminance,'String'));
%%

Hfdistinguish=figure ('WindowStyle','normal','toolbar','Figure','Color','w','Name','View-Edit classification','NumberTitle','off',...
    'Units','Normalized','Position',[0.1 0.4 0.85 0.5],'Resizefcn','');
ax=axes('Units','Normalized','Position',[0.02 0.025 0.978 0.974],...
    'box','off','Parent',Hfdistinguish,'Visible','off');

% modify tool bar
tempbar= findall(findall(Hfdistinguish,'Type','uitoolbar'));
delete(tempbar([2:7 9 13 16 17]));
% % Reorder tools
% set(temp(1),'Children',[temp(4:end-1);temp(2:3);temp(end)])



bColorScheme=uitoggletool(tempbar(1),'Tag','Seperate','Cdata',imread('ColorScheme.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','Change color scheme',...
    'HandleVisibility','on','ClickedCallback',@changeColorScheme,'state','off');

uipushtool(tempbar(1),'Tag','Seperate','Cdata',imread('ClassUseOtherImage.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','Load different grayscale image, of same size for classification purpose',...
    'HandleVisibility','on','ClickedCallback',@BrowseClass);


bremove_along_path=uitoggletool(tempbar(1),'Tag','Seperate','Cdata',imread('seperateS.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','Remove pixels along the drawn path',...
    'HandleVisibility','on','ClickedCallback',@remove_along_path,'state','off');

bdraw_along_path=uitoggletool(tempbar(1),'Tag','Seperate','Cdata',imread('drawS.png','BackgroundColor',[1 1 1]),...
    'Separator','off','TooltipString','add pixels along the drawn path',...
    'HandleVisibility','on','ClickedCallback',@draw_along_path,'state','off');

bremove_bregion=uitoggletool(tempbar(1),'Tag','RemRegion','Cdata',imread('removeS.png','BackgroundColor',[1 1 1]),...
    'Separator','off','TooltipString','Remove binary region',...
    'HandleVisibility','on','ClickedCallback',@remove_bregion,'state','off');


bundo_last_action=uipushtool(tempbar(1),'Tag','Undo last remove or add','Cdata',imread('undo.jpeg'),...
    'Separator','on','TooltipString','Undo last remove path action',...
    'HandleVisibility','on','Enable','off','ClickedCallback',@undo_last_action);


uipushtool(tempbar(1),'Tag','s2Reject','Cdata',imread('reject.png','BackgroundColor',[1 1 1]),...
    'Separator','off','TooltipString','Select object to ckassify as rejected',...
    'HandleVisibility','on','ClickedCallback',@eval_mark,'Enable','on');
uipushtool(tempbar(1),'Tag','s2Timemark','Cdata',imread('timemark.png','BackgroundColor',[1 1 1]),...
    'Separator','off','TooltipString','Select object to ckassify as timemark',...
    'HandleVisibility','on','ClickedCallback',@eval_mark,'Enable','on');
uipushtool(tempbar(1),'Tag','s2Trace','Cdata',imread('trace.png','BackgroundColor',[1 1 1]),...
    'Separator','off','TooltipString','Select object to ckassify as trace',...
    'HandleVisibility','on','ClickedCallback',@eval_mark,'Enable','on');

uipushtool(tempbar(1),'Tag','Show whole seismogram','Cdata',imread('whole_seismogram.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','Show whole seismogram',...
    'HandleVisibility','on','ClickedCallback',@zoom2seismogramCLASS);

uipushtool(tempbar(1),'Tag','s2Trace','Cdata',imread('zoom2region.png','BackgroundColor',[1 1 1]),...
    'Separator','off','TooltipString','Zoom DigitSeis main axis to the region displayed in the classification figure',...
    'HandleVisibility','on','ClickedCallback',@zoom2region,'Enable','on');



bReAssign_Objects_to_Traces=uipushtool(tempbar(1),'Tag','s2Trace','Cdata',imread('AssignObjectsToTraces.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','Assign objects to traces',...
    'HandleVisibility','on','ClickedCallback',@ReAssign_Objects_to_Traces,'Enable','on');

hToolbar = findall(Hfdistinguish,'tag','FigureToolBar');



drawnow % Needed before jToolbar line
% since Matlab only allows only uipushtools & uitoggletools to toolbars I'm using a Java component.
jToolbar = get(get(hToolbar,'JavaContainer'),'ComponentPeer');
drawnow

jModel = javax.swing.SpinnerNumberModel(level,1,99,1);
jSpinner = javax.swing.JSpinner(jModel);
jSpinner =handle(jSpinner,'callbackproperties');
jSpinner.setToolTipText('Change binary threshold');
jSpinner.setSize(70,25);
jSpinner(1).setPreferredSize(java.awt.Dimension(70,25));
jSpinner.setMaximumSize(java.awt.Dimension(100,25));


JCheckBox=javax.swing.JCheckBox();
JCheckBox.setSize(30,25);
hJCheckBox = handle(JCheckBox,'callbackproperties');
hJCheckBox.ActionPerformedCallback = @Show_Object_assignments;

Jbox=javax.swing.Box.createHorizontalGlue();
Jbox.setSize(300,25);


temp=zeros(16,16,3,'uint8');
temp(:,:,1)=255;
uipushtool(tempbar(1),'Tag','recalcCLASS','Cdata',temp,...
    'Separator','on','TooltipString','Recalculate Classification',...
    'HandleVisibility','on','ClickedCallback',@recalculate_callback);

%Create button image & Button
temp=zeros([16,16,3],'uint8'); rng(1980) ;
for ii=1:10
    temp(randi([2,15],6,1),randi([2 15],1),1)=255;
end
for ii=2:16, temp(ii-1:ii,ii-1:ii,:)=255; temp([ii-1:ii],17-[ii-1:ii],:)=255; end
uipushtool(tempbar(1),'Tag','DeleteReds','Cdata',temp,...
    'Separator','off','TooltipString','Delete noise objects (saves memory)',...
    'HandleVisibility','on','Enable','on','ClickedCallback',@deleteRedObjects);


% Add here 1 for each new button.
jToolbar.add(Jbox,23);
jToolbar.add(JCheckBox,24);
jToolbar.add(jSpinner,27);


%@bShow_Object_assignments

jToolbar.repaint;
jToolbar.revalidate;


htext=text(mean(get(ax,'xlim')),mean(get(ax,'ylim')), 'please wait',...
    'HorizontalAlignment','Center','Parent',ax,'FontSize',32,'BackgroundColor','w');
drawnow


%%
% retrieve some info for classification
[rows,cols]=size(BW);
tick_length=str2double(get(H.edit_tick_xlength,'String'));

G=zeros(rows,cols,'uint8'); R=G; B=G;

itickL=[S.ID]==1;
itraceL=[S.ID]==0;

irej=cell2mat({S([S.ID]==-1).PixelIdxList}');
itick=cell2mat({S(itickL).PixelIdxList}');
itrace=cell2mat({S(itraceL).PixelIdxList}');


if strcmpi(get(bColorScheme,'state'),'off')
    R([irej;itrace])=255;
    G([itick; itrace])=255;
    B(itrace)=255;
else
    R([irej;itrace])=255;
    B([itick;itrace])=255;
    G(itick)=220;
    G(itrace)=255;
end

I_RGB=zeros(rows,cols,3,'uint8');
I_RGB(:,:,1)=R; I_RGB(:,:,2)=G; I_RGB(:,:,3)=B;


HIMRGB=image(I_RGB);
drawnow
delete(htext)

BW0=BW;
S0=S;


mult_bck_color=[0.7 0.7 0.7]; % NOT WHITE color for textbox when multiple assignments.
iwithnuminS=[];
imultiple_inS=[];
hObjAssignmentLabel=[];
if isfield(S,'TraceNum')
    ineg= cellfun(@isempty,{S.TraceNum});
    [S(ineg).TraceNum]=deal(-1);
    Update_AssignementLabelsfromS();
end



    function  ReAssign_Objects_to_Traces(hObject, eventdata)
        global pt_traces ftrend
        
        try
            delete(hObjAssignmentLabel)
        end
        
        over_under=str2num(get(H.edit_offset,'string')); %#ok<ST2NM>
        [rows,cols]=size(BW);
        
        fX=ftrend(cell2mat(cellfun(@(v) v(1),get(pt_traces,'Xdata'),'UniformOutput',false)));
        Y=cell2mat(cellfun(@(v) v(1),get(pt_traces,'Ydata'),'UniformOutput',false));
        meanOffset=mode(abs(diff(Y)));
        
        Bbox=cell2mat({S.BoundingBox}');
        itickL=[S.ID]==1;
        itraceL=[S.ID]==0;
        
        C=[Bbox(:,2)+Bbox(:,4)/2,Bbox(:,1)+Bbox(:,3)/2, [1:size(Bbox,1)]']; % the last column is just the initial index.
        Ctick=C(itickL,:);
        C=C(itraceL,:);
        
        [S.TraceNum]=deal(-1);
        for i=1:numel(pt_traces)
            
            % prepare stripes
            zerotrace_i= Y(i)-fX(i)+ftrend(C(:,2));
            itrace_i=C(:,1) > over_under(1)*meanOffset+zerotrace_i &...
                C(:,1) < over_under(2)*meanOffset+zerotrace_i;
            zerotick_i=Y(i)-fX(i)+ftrend(Ctick(:,2));
            
            if  strcmpi(get(H.timemarkpos,'State'),'off') % time marks above the trace
                itick_i=Ctick(:,1) > -abs(over_under(1))*meanOffset+zerotick_i-meanOffset/2 &...
                    Ctick(:,1) < zerotick_i;
            elseif strcmpi(get(H.timemarkpos,'State'),'on')  % time marks bellow the trace
                itick_i=Ctick(:,1) < abs(over_under(2))*meanOffset+zerotick_i+meanOffset/2 &...
                    Ctick(:,1) > zerotick_i;
            end
            
            [S(C(itrace_i,end)).TraceNum]=deal(i);
            [S(Ctick(itick_i,end)).TraceNum]=deal(i);
        end
        
        
        cm=lines(numel(pt_traces))+0.1;
        cm(cm>1)=1;
        iwithnuminS=cellfun(@(x)(x(1)>0),{S.TraceNum}); % find all with 1st TraceNum > 0
        if any(imultiple_inS)
            imultiple_inS=cellfun(@(x) numel(x)>1,{S.TraceNum}); % find  the ones with multiple numbers in TraceNum
        end
        
        
        hObjAssignmentLabel=text(Bbox(iwithnuminS,1)+Bbox(iwithnuminS,3)/2,Bbox(iwithnuminS,2)+Bbox(iwithnuminS,4)/2, num2str([S(iwithnuminS).TraceNum]'),...
            'Color','k','FontUnits','Pixels','FontSize',7,'Interpreter','none','Visible','on','Margin',1,'ButtonDownFcn',@Correct_Object_Trace_Assignment);
        tempTN=[S(iwithnuminS).TraceNum]';
        for i=1:length(hObjAssignmentLabel)
            hObjAssignmentLabel(i).BackgroundColor= cm(tempTN(i),:);
        end
        if any(imultiple_inS)
            hObjAssignmentLabel(imultiple_inS).BackgroundColor=mult_bck_color; % paint all with multiple assignments black
        end
        
        Show_Object_assignments;
        drawnow
        
    end


    function Update_AssignementLabelsfromS(hObject,eventdata)
        global pt_traces
        
        try
            delete(hObjAssignmentLabel)
        end
        
        Bbox=cell2mat({S.BoundingBox}');
        %         iwithnum= ~cellfun(@(x)(x>0),{S.TraceNum});
        %         iwithnuminS= find(iwithnum);
        
        [S(~(itickL | itraceL)).TraceNum]=deal(-1);
        
        cm=lines(numel(pt_traces))+0.1;
        cm(cm>1)=1;
        
        
        iwithnuminS=cellfun(@(x)(x(1)>0),{S.TraceNum}); % find all with 1st TraceNum > 0
        imultiple_inS=cellfun(@(x) numel(x)>1,{S.TraceNum}); % find  the ones with multiple numbers in TraceNum
        
        
        hObjAssignmentLabel=text(Bbox(iwithnuminS,1)+Bbox(iwithnuminS,3)/2,Bbox(iwithnuminS,2)+Bbox(iwithnuminS,4)/2, num2str([S(iwithnuminS).TraceNum]'),...
            'Color','k','FontUnits','Pixels','FontSize',7,'Interpreter','none','Visible','on','Margin',1,'ButtonDownFcn',@Correct_Object_Trace_Assignment);
        
        tempTN=[S(iwithnuminS).TraceNum]';
        
        for i=1:length(hObjAssignmentLabel)
            hObjAssignmentLabel(i).BackgroundColor= cm(tempTN(i),:);
        end
        if any(imultiple_inS)
            hObjAssignmentLabel(imultiple_inS).BackgroundColor=mult_bck_color; % paint all with multiple assignments black
        end
        
        Show_Object_assignments;
        drawnow
        
    end



    function  Correct_Object_Trace_Assignment(hObject, eventdata)
        global pt_traces
        
        oldcolor=hObject.BackgroundColor;
        oldassignment=str2num(hObject.String); %#ok<ST2NM>
        oldmargin=hObject.Margin;
        
        set(hObject,'Margin',4,'BackgroundColor',[1 1 1])
        drawnow;
        hObject.Editing='on';
        waitfor(hObject,'Editing','off')
        try
            newassignment= round(str2num(hObject.String)); %#ok<ST2NM>
        catch
            warndlg(sprintf('Invalid assignment format it should be either an integer or in the form [integer1 integer2 ...]'));
            set(hObject,'Margin',oldmargin,'BackgroundColor',oldcolor,'String',num2str(oldassignment));
            return
        end
        
        if all(newassignment>=1) && all(newassignment<=length(pt_traces))
            iobj=findobj(hObjAssignmentLabel,'Margin',4,'BackgroundColor',[1 1 1]);
            if isempty(iobj)
                return
            end
            i=find(iobj==hObjAssignmentLabel,1);
            index=find(iwithnuminS);
            S(index(i)).TraceNum=newassignment;
            
            if numel(newassignment)==1
                iother=find([S(iwithnuminS).TraceNum]==S(index(i)).TraceNum,1);% this will return empty or maximum 1 result.
                set(hObject,'Margin',oldmargin,'BackgroundColor',hObjAssignmentLabel(iother).BackgroundColor);
            else
                set(hObject,'Margin',oldmargin,'BackgroundColor',mult_bck_color); % set color to mult_bck_color
            end
            drawnow;
        else
            warndlg(sprintf('You should enter integers between 1 and %d',length(pt_traces)));
            set(hObject,'Margin',oldmargin,'BackgroundColor',oldcolor,'String',num2str(oldassignment));
        end
        drawnow
    end




    function Show_Object_assignments(hObject, eventdata)
        
        
        if ~isempty(hObjAssignmentLabel)
            if JCheckBox.isSelected
                set(hObjAssignmentLabel,'Visible','on')
            else
                set(hObjAssignmentLabel,'Visible','off')
            end
        else
            
        end
    end





    function  changeColorScheme(hObject, eventdata)
        ht1=text(mean(get(ax,'xlim')),mean(get(ax,'ylim')), 'please wait',...
            'HorizontalAlignment','Center','Parent',ax,'FontSize',32,'BackgroundColor','w');
        drawnow;
        
        G=zeros(rows,cols,'uint8'); R=G; B=G;
        if strcmpi(get(bColorScheme,'state'),'off')
            R([irej;itrace])=255;
            G([itick; itrace])=255;
            B(itrace)=255;
        else
            R([irej;itrace])=255;
            B([itick;itrace])=255;
            G(itick)=220;
            G(itrace)=255;
        end
        I_RGB(:,:,1)=R; I_RGB(:,:,2)=G; I_RGB(:,:,3)=B;
        set(HIMRGB,'CDATA',I_RGB);
        delete(ht1);
        drawnow
        
    end



    function BrowseClass(hObject, eventdata)
        
        button = questdlg({'Are you sure you want to recalculate classification using a new image?';'Current classification will be lost!'},'Confirmation','Yes','No','No');
        if strcmpi(button,'No')
            return
        end
        
        
        [filename, pathname]=uigetfile({'*.jpg;*.tif;*.png;*.gif','All Image Files';...
            '*.*','All Files' },'Select grayscale image of identical dimensions to use for classification.');
        if isequal(filename,0)
            return
        end
        
        ht1=text(mean(get(ax,'xlim')),mean(get(ax,'ylim')), 'please wait',...
            'HorizontalAlignment','Center','Parent',ax,'FontSize',32,'BackgroundColor','w');
        drawnow;
        
        ffile=fullfile(pathname,filename);
        
        BW=im2uint8(imread(ffile));
        button = questdlg('Press Yes to consider the complement of the scanned image','Image polarity','Yes','No','Yes');
        if strcmp(button,'Yes')
            BW= imcomplement(BW);
        end
        BW=im2bw(BW,get(jSpinner,'Value')/100);
        
        Classification_Recalculate;
        update_classification_plot;
        
        delete(ht1);
        drawnow;
        
    end



    function deleteRedObjects(hObject, eventdata)
        
        button = questdlg('Are you sure you want to delete all noise objects?\n This action cannot be undone','Image polarity','Yes','No','No');
        if strcmp(button,'No')
            return;
        end
        
        
        ht=text(mean(get(ax,'xlim')),mean(get(ax,'ylim')), 'Removing noise, please wait',...
            'HorizontalAlignment','Center','Parent',ax,'FontSize',32,'BackgroundColor','w');
        drawnow;
        
        % remove reds
        itoremove=[S.ID]==-1;
        if sum(itoremove)>0
            S([S.ID]==-1)=[];
            update_classification_plot;
        end
        delete(ht)
    end



    function zoom2seismogramCLASS(hObject, eventdata)
        set(ax,'Xlim',[1 size(BW,2)],'Ylim',[1,size(BW,1)])
        drawnow;
        Reset_MouseMotionMon;
    end

    function zoom2region(hObject, eventdata)
        set(H.ax1,'Xlim',get(ax,'Xlim'),'Ylim',get(ax,'Ylim'))
        drawnow;
        Reset_MouseMotionMon;
    end


    function recalculate_callback(h,e)
        
        button = questdlg({'Are you sure you want to recalculate classification using the original image?';'Current classification will be lost!'},'Confirmation','Yes','No','No');
        if strcmpi(button,'No')
            return
        end
        
        ht1=text(mean(get(ax,'xlim')),mean(get(ax,'ylim')), 'please wait',...
            'HorizontalAlignment','Center','Parent',ax,'FontSize',32,'BackgroundColor','w');
        drawnow;
        
        %get(jSpinner,'Value')
        BW=im2bw(I0,get(jSpinner,'Value')/100);%bradleyPetros(I0,[256 256],get(jSpinner,'Value'));
        
        Classification_Recalculate;
        update_classification_plot;
        
        delete(ht1);
        drawnow;
    end

    function  Classification_Recalculate()%(hObject, eventdata)
        global tick_length_lim
        S=regionprops(BW,{'BoundingBox','PixelIdxList'});
        % add the id field 0 for normal trace, 1 for time mark, -1 for
        % rejected objects
        
        time_length=cell2mat({S.BoundingBox}');
        time_length=time_length(:,3)';% tale width;
        
        %idRej=time_length>tick_length+5 | time_length<tick_length-5; % normal trace or too short objects
        
        if tick_length>0
            idTick=abs(time_length-tick_length)<tick_length_lim*tick_length;
            idTrace=time_length-tick_length>tick_length_lim*tick_length;
        else
            idTick=[];
            idTrace=time_length+tick_length>tick_length_lim*(-tick_length);
        end
        
        
        [S(idTrace).ID]=deal(0);
        [S(idTick).ID]=deal(1);
        idRej=cellfun(@(x) isempty(x),{S.ID});
        [S(idRej).ID]=deal(-1);
        
        [S(idRej).TraceNum]=deal(-1);
        
    end




    function idx=Classification_UpdateADD(linearIdx)
        global tick_length_lim
        
        idx=linearIdx;
        
        PixelIdxList=cell2mat({S.PixelIdxList}');
        if isempty(intersect(linearIdx,PixelIdxList))
            
            % create temp binary image and detect connected objects
            [i,j] = ind2sub(size(BW),linearIdx);
            BoundingBox=[min(j)-0.5 min(i)-0.5 max(j)-min(j)+1 max(i)-min(i)+1];
            bwtemp=false(BoundingBox([4 3]));
            b0=floor(BoundingBox);
            [i1,j1]=ind2sub(size(BW),linearIdx);
            bwtemp(sub2ind(size(bwtemp),i1-b0(2),j1-b0(1)))=true;
            Stemp=regionprops(bwtemp,'BoundingBox','PixelList');
            
            nend=length(S);
            for i=1:length(Stemp)
                S(nend+i).PixelIdxList=...
                    sub2ind(size(BW),Stemp(i).PixelList(:,2)+b0(2),Stemp(i).PixelList(:,1)+b0(1));
                S(nend+i).BoundingBox=...
                    [Stemp(i).BoundingBox(1)+b0(1),...
                    Stemp(i).BoundingBox(2)+b0(2),...
                    Stemp(i).BoundingBox(3), Stemp(i).BoundingBox(4)];
                
                
                
                % clasiffy it
                if tick_length>0
                    if abs(S(nend+i).BoundingBox(3)-tick_length)<=tick_length_lim*tick_length;
                        S(nend+i).ID=1;
                    elseif S(nend+i).BoundingBox(3)-tick_length>tick_length_lim*tick_length;
                        S(nend+i).ID=0;
                    else
                        S(nend+i).ID=-1;
                    end
                else
                    if S(nend+i).BoundingBox(3)+tick_length>tick_length_lim*(-tick_length);
                        S(nend+i).ID=0;
                    else
                        S(nend+i).ID=-1;
                    end
                end
            end
            return
        else
            
            for iter=1:length(S)
                if ~isempty(intersect(linearIdx,S(iter).PixelIdxList))
                    temp_union=union(S(iter).PixelIdxList,linearIdx);
                    [i,j] = ind2sub(size(BW),temp_union);
                    
                    BoundingBox=[min(j)-0.5 min(i)-0.5 max(j)-min(j)+1 max(i)-min(i)+1];
                    
                    bwtemp=false(BoundingBox([4 3]));
                    b0=floor(BoundingBox);
                    
                    [i1,j1]=ind2sub(size(BW),temp_union);
                    bwtemp(sub2ind(size(bwtemp),i1-b0(2),j1-b0(1)))=true;
                    
                    Stemp=regionprops(bwtemp,'BoundingBox','PixelList');
                    
                    S(iter).PixelIdxList=...
                        sub2ind(size(BW),Stemp(1).PixelList(:,2)+b0(2),Stemp(1).PixelList(:,1)+b0(1));
                    S(iter).BoundingBox=...
                        [Stemp(1).BoundingBox(1)+b0(1),...
                        Stemp(1).BoundingBox(2)+b0(2),...
                        Stemp(1).BoundingBox(3), Stemp(1).BoundingBox(4)];
                    
                    if tick_length>0
                        if abs(S(iter).BoundingBox(3)-tick_length)<=tick_length_lim*tick_length;
                            S(iter).ID=1;
                        elseif S(iter).BoundingBox(3)-tick_length>tick_length_lim*tick_length;
                            S(iter).ID=0;
                        else
                            S(iter).ID=-1;
                        end
                    else
                        if S(iter).BoundingBox(3)+tick_length>tick_length_lim*(-tick_length);
                            S(iter).ID=0;
                        else
                            S(iter).ID=-1;
                        end
                    end
                    
                    nend=length(S);
                    
                    idx=[iter, nend+[1:length(Stemp)-1]];
                    
                    
                    for i=2:length(Stemp)
                        S(nend+i-1).PixelIdxList=...
                            sub2ind(size(BW),Stemp(i).PixelList(:,2)+b0(2),Stemp(i).PixelList(:,1)+b0(1));
                        S(nend+i-1).BoundingBox=...
                            [Stemp(i).BoundingBox(1)+b0(1),...
                            Stemp(i).BoundingBox(2)+b0(2),...
                            Stemp(i).BoundingBox(3), Stemp(i).BoundingBox(4)];
                        
                        if tick_length>0
                            if abs(S(nend+i-1).BoundingBox(3)-tick_length)<=tick_length_lim*tick_length;
                                S(nend+i-1).ID=1;
                            elseif S(nend+i-1).BoundingBox(3)-tick_length>tick_length_lim*tick_length;
                                S(nend+i-1).ID=0;
                            else
                                S(nend+i-1).ID=-1;
                            end
                        else
                            if S(nend+i-1).BoundingBox(3)+tick_length>tick_length_lim*(-tick_length);
                                S(nend+i-1).ID=0;
                            else
                                S(nend+i-1).ID=-1;
                            end
                        end
                    end
                    
                    return
                end
            end
        end
        
        
    end

    function idx=Classification_UpdateREMOVE_BREGION(linearIdx)
        global tick_length_lim
        idx=[];
        tempS=[];
        
        %find affected objects
        iok=cellfun(@(x) ~isempty(intersect(linearIdx,x)),{S.PixelIdxList});
        idx=find(iok);
        currentNofobjects=length(idx);
        if ~any(iok)
            idx=[];
            return;
        end
        % create a sub-image with all these objects
        BBox=reshape([S(iok).BoundingBox],4,currentNofobjects)';
        PixelIdxList=cellfun(@(x) (x(:)), {S(iok).PixelIdxList},'UniformOutput',false);
        PixelIdxList=cell2mat(PixelIdxList(:));
        b0=[floor(min(BBox(:,1))) floor(min(BBox(:,2))),max(floor(BBox(:,1))+BBox(:,3)),max(floor(BBox(:,2))+BBox(:,4))];
        b0(3:4)=[b0(3)-b0(1) b0(4)-b0(2)];
        bwtemp=false(b0(4),b0(3));
       
        % apply remove region
        [i1,j1]=ind2sub(size(BW),setdiff(PixelIdxList,linearIdx));
        bwtemp(sub2ind(size(bwtemp),i1-b0(2),j1-b0(1)))=true;
        
        % recalculate objects
        Stemp=regionprops(bwtemp,'BoundingBox','PixelList');
        newNofobjects=length(Stemp);
        
        S(iok)=[];
        nend=length(S);
        
        
        %remove  affected objects from current structre
        % put new objects after the end of S. % PETROS: this can be accelerated
        for i=1:newNofobjects
            S(nend+i).PixelIdxList=...
                sub2ind(size(BW),Stemp(i).PixelList(:,2)+b0(2),Stemp(i).PixelList(:,1)+b0(1));
            S(nend+i).BoundingBox=...
                [Stemp(i).BoundingBox(1)+b0(1),...
                Stemp(i).BoundingBox(2)+b0(2),...
                Stemp(i).BoundingBox(3), Stemp(i).BoundingBox(4)];
            
            if tick_length>0
                if abs(S(nend+i).BoundingBox(3)-tick_length)<=tick_length_lim*tick_length;
                    S(nend+i).ID=1;
                elseif S(nend+i).BoundingBox(3)-tick_length>tick_length_lim*tick_length;
                    S(nend+i).ID=0;
                else
                    S(nend+i).ID=-1;
                end
            else
                if S(nend+i).BoundingBox(3)+tick_length>(tick_length_lim*(-tick_length));
                    S(nend+i).ID=0;
                else
                    S(nend+i).ID=-1;
                end
            end
        end
        
        idx=nend+[1:newNofobjects];
    end











    function idx=Classification_UpdateREMOVE(linearIdx)
        global tick_length_lim
        idx=[];
        for iter=1:length(S)
            if ~isempty(intersect(linearIdx,S(iter).PixelIdxList))
                bwtemp=false(S(iter).BoundingBox([4 3]));
                b0=floor(S(iter).BoundingBox);
                
                [i1,j1]=ind2sub(size(BW),setdiff(S(iter).PixelIdxList,linearIdx));
                bwtemp(sub2ind(size(bwtemp),i1-b0(2),j1-b0(1)))=true;
                
                Stemp=regionprops(bwtemp,'BoundingBox','PixelList');
                
                
                S(iter).PixelIdxList=...
                    sub2ind(size(BW),Stemp(1).PixelList(:,2)+b0(2),Stemp(1).PixelList(:,1)+b0(1));
                S(iter).BoundingBox=...
                    [Stemp(1).BoundingBox(1)+b0(1),...
                    Stemp(1).BoundingBox(2)+b0(2),...
                    Stemp(1).BoundingBox(3), Stemp(1).BoundingBox(4)];
                
                if tick_length>0
                    if abs(S(iter).BoundingBox(3)-tick_length)<=tick_length_lim*tick_length;
                        S(iter).ID=1;
                    elseif S(iter).BoundingBox(3)-tick_length>tick_length_lim*tick_length;
                        S(iter).ID=0;
                    else
                        S(iter).ID=-1;
                    end
                else
                    if S(iter).BoundingBox(3)+tick_length>tick_length_lim*(-tick_length);
                        S(iter).ID=0;
                    else
                        S(iter).ID=-1;
                    end
                end
                nend=length(S);
                
                idx=[iter, nend+[1:length(Stemp)-1]];
                
                
                for i=2:length(Stemp)
                    S(nend+i-1).PixelIdxList=...
                        sub2ind(size(BW),Stemp(i).PixelList(:,2)+b0(2),Stemp(i).PixelList(:,1)+b0(1));
                    S(nend+i-1).BoundingBox=...
                        [Stemp(i).BoundingBox(1)+b0(1),...
                        Stemp(i).BoundingBox(2)+b0(2),...
                        Stemp(i).BoundingBox(3), Stemp(i).BoundingBox(4)];
                    
                    if tick_length>0
                        if abs(S(nend+i-1).BoundingBox(3)-tick_length)<=tick_length_lim*tick_length;
                            S(nend+i-1).ID=1;
                        elseif S(nend+i-1).BoundingBox(3)-tick_length>tick_length_lim*tick_length;
                            S(nend+i-1).ID=0;
                        else
                            S(nend+i-1).ID=-1;
                        end
                    else
                        if S(nend+i-1).BoundingBox(3)+tick_length>(tick_length_lim*(-tick_length));
                            S(nend+i-1).ID=0;
                        else
                            S(nend+i-1).ID=-1;
                        end
                    end
                end
                
                return
            end
        end
        
        
    end



    function update_classification_plot(iter)%hobject,eventdata)%(hObject, eventdata)
        
        if nargin==1
            if strcmpi(get(bColorScheme,'state'),'off')
                TickColor=[0 255 0];
            else
                TickColor=[0 220 255];
            end
            
            
            for it=iter
                [i,j]=ind2sub(size((BW)),[S(it).PixelIdxList]);
                id=sub2ind([rows,cols],i,j);
                if S(it).ID==-1
                    rgb=[255 0 0];
                elseif S(it).ID==1
                    rgb=TickColor;
                else
                    rgb=[255 255 255];
                end
                I_RGB(id)=rgb(1);
                I_RGB(id+numel(BW))=rgb(2);
                I_RGB(id+2*numel(BW))=rgb(3);
            end
        else
            G(:)=0; R(:)=0; B(:)=0;
            irej=cell2mat({S([S.ID]==-1).PixelIdxList}');
            itick=cell2mat({S([S.ID]==1).PixelIdxList}');
            itrace=cell2mat({S([S.ID]==0).PixelIdxList}');
            
            
            if strcmpi(get(bColorScheme,'state'),'off')
                R([irej;itrace])=255;
                G([itick; itrace])=255;
                B(itrace)=255;
            else
                R([irej;itrace])=255;
                B([itick;itrace])=255;
                G(itick)=220;
                G(itrace)=255;
            end
            
            I_RGB(:,:,1)=R; I_RGB(:,:,2)=G; I_RGB(:,:,3)=B;
        end
        set(HIMRGB,'CDATA',I_RGB);
        
        
    end


    function update_BW_plot(linearInd,new_value)%hobject,eventdata)%(hObject, eventdata)
        % updates the 
        if new_value
            irej=cell2mat({S([S.ID]==-1).PixelIdxList}');
            itick=cell2mat({S([S.ID]==1).PixelIdxList}');
            itrace=cell2mat({S([S.ID]==0).PixelIdxList}');
            
            
            if strcmpi(get(bColorScheme,'state'),'off')
                R([irej;itrace])=255;
                G([itick; itrace])=255;
                B(itrace)=255;
            else
                R([irej;itrace])=255;
                B([itick;itrace])=255;
                G(itick)=220;
                G(itrace)=255;
            end
            
            I_RGB(:,:,1)=R; I_RGB(:,:,2)=G; I_RGB(:,:,3)=B;
            
        else
            I_RGB([linearInd+0;linearInd+ numel(BW);linearInd+ 2*numel(BW)])=new_value;
        end
        set(HIMRGB,'CDATA',I_RGB);
        
    end

    function remove_bregion(hObject, eventdata)
        
        while strcmpi(get(bremove_bregion,'State'),'on')
            hfh=imfreehand(ax,'closed',true);
            hfh.Deletable = false;
            try
                mask=hfh.createMask;
                delete(hfh);
            catch
                delete(hfh);
                break
            end
                
            % create undo point
            S0=S;
            BW0=BW;
            set(bundo_last_action,'Enable','on');
            
            %update BW
            
            % update plot
            linearIdx=find(mask);
            BW(mask)=false;
            update_BW_plot(linearIdx,false)
             drawnow;
            idx=Classification_UpdateREMOVE_BREGION(linearIdx);
            if ~isempty(idx)
                update_classification_plot(idx);
                
            end
            drawnow;
        end
        
        set(bremove_bregion,'State','off');
        
    end


    function remove_along_path(hObject, eventdata)
        
        while strcmpi(get(bremove_along_path,'State'),'on')
            
            hfh=imfreehand(ax,'closed',false);
            hfh.Deletable = false;
            try
                pos=hfh.getPosition;
            catch
                delete(hfh); 
                return
            end
            
            if size(pos,1)<2 || strcmpi(get(bremove_along_path,'State'),'off')
                delete(hfh);
                set(bremove_along_path,'State','off')
                return
            end
            delete(hfh);
            
            S0=S;
            BW0=BW;
            set(bundo_last_action,'Enable','on');
            
            if range(pos(:,1))>range(pos(:,2))
                [~,iu]=unique(pos(:,1));
                pos=pos(iu,:);
                cx= min(pos(:,1)):max(pos(:,1));
                cy= interp1(pos(:,1),pos(:,2),cx,'linear');
                % make it thick
                cx=[cx(:);cx(:)];
                cy=[cy(:);cy(:)+1];
            else
                [~,iu]=unique(pos(:,2));
                pos=pos(iu,:);
                cy= min(pos(:,2)):max(pos(:,2));
                cx= interp1(pos(:,2),pos(:,1),cy,'linear');
                % make it thick
                cy=[cy(:);cy(:)];
                cx=[cx(:);cx(:)+1];
            end
            
            linearIdx = sub2ind([rows,cols], round(cy),round(cx));
            BW(linearIdx)=false;
            
            update_BW_plot(linearIdx,false);
            
            idx=Classification_UpdateREMOVE(linearIdx);
            if ~isempty(idx)
                update_classification_plot;
            end
            drawnow;
            
        end
        
        set(bremove_along_path,'State','off');
    end




    function draw_along_path(hObject, eventdata)
        
        while strcmpi(get(bdraw_along_path,'State'),'on')
            
            hfh=imfreehand(ax,'closed',false);
            hfh.Deletable = false;
            pos=hfh.getPosition;
            
            if strcmpi(get(bdraw_along_path,'State'),'off')
                delete(hfh);
                set(bdraw_along_path,'State','off')
                return
            end
            delete(hfh);
            
            S0=S;
            BW0=BW;
            set(bundo_last_action,'Enable','on');
            
            if range(pos(:,1))>range(pos(:,2))
                %[~,iu]=unique(pos(:,1));
                [~,iu]=sort(pos(:,1));
                pos=pos(iu,:) + 0.001*rand(size(pos));
                cx= min(pos(:,1)):max(pos(:,1));
                cy= interp1(pos(:,1),pos(:,2),cx,'linear');
                % make it thick
                cx=[cx(:);cx(:);cx(:);cx(:)];
                cy=[cy(:);cy(:)+1;cy(:)+2;cy(:)+3];
            else
                [~,iu]=unique(pos(:,2));
                pos=pos(iu,:);
                cy= min(pos(:,2)):max(pos(:,2));
                cx= interp1(pos(:,2),pos(:,1),cy,'linear');
                % make it thick
                cy=[cy(:);cy(:);cy(:);cy(:)];
                cx=[cx(:);cx(:)+1;cx(:)+2;cx(:)+3];
            end
            
            linearIdx = sub2ind([rows,cols], round(cy),round(cx));
            BW(linearIdx)=true;
            
            update_BW_plot(linearIdx,true);
            
            idx=Classification_UpdateADD(linearIdx);
            if ~isempty(idx)
                update_classification_plot;
            end
            drawnow;
            
        end
        
        set(bdraw_along_path,'State','off');
    end



    function undo_last_action(hObject, eventdata)
        
        BW=BW0;
        S=S0;
        set(bundo_last_action,'Enable','off');
        update_classification_plot;
        drawnow
    end


    function eval_mark(hObject, eventdata)
        tag=get(hObject,'tag');
        if strcmp(tag,'s2Trace')
            id=0;
        elseif strcmp(tag,'s2Reject')
            id=-1;
        elseif strcmp(tag,'s2Timemark')
            id=1;
        else
            error('Problem in modify classification')
        end
        
        
        zoom off
        [colSub,rowSub,butt]=ginput(1);
        
        while butt==1
            linearInd = sub2ind([rows,cols], round(rowSub), round(colSub));
            for iter=1:length(S)
                if any(linearInd==S(iter).PixelIdxList)
                    S(iter).ID=id;
                    update_classification_plot(iter);
                    drawnow
                    break;
                end
            end
            
            [colSub,rowSub,butt]=ginput(1);
        end
        
    end


set (H.f1, 'WindowButtonMotionFcn', @mouseMove)
end

%%
















function adjust_traces(hObject, eventdata)
global H I0 ftrend pt_traces pt_traceLABEL

dat=cell(numel(pt_traces),4);
for i=1:numel(pt_traces)
    x=get(pt_traces(i),'XDATA');
    y=get(pt_traces(i),'YDATA');
    dat(i,:)={ y(1),x(1), x(end), true };
end
% sort by ascending 1st y-pixel
firstyat_1=ftrend(1)+[dat{:,1}]'-ftrend([dat{:,2}]);

[~,idat]=sort(firstyat_1);
dat=dat(idat,:);
pt_traces=pt_traces(idat);


f = figure('Units','Normalized','Position',[0.8 0.25 0.15 0.5],'color','w',...
    'WindowStyle','normal','Menubar','None','Toolbar','none',...
    'NumberTitle','Off','Name','Adjust traces');
columnname =   {'First y-pixel','First x-pixel','Last x-pixel','Active'};
columnformat = {'numeric','numeric', 'numeric','logical'};
columneditable =  [true true true true];
t = uitable('Units','normalized','Position',...
    [0.01 0.1 0.98 0.89], 'Data', dat,...
    'ColumnName', columnname,...
    'ColumnFormat', columnformat,...
    'ColumnEditable', columneditable,...
    'RowName',1:numel(pt_traces));

apply_changes=uicontrol('Style', 'pushbutton','Parent',f,'units','normalized',...
    'String', 'Apply changes','Position', [0.67 0.02 0.3 0.05],'Callback',@apply_table_changes);

add_trace=uicontrol('Style', 'pushbutton','Parent',f,'units','normalized',...
    'String', '+','Position', [0.52 0.02 0.12 0.05],'Callback',@fadd_trace);

uiwait(gcf);

    function fadd_trace(hObject, eventdata)
        [r,c]=size(I0);
        
        ans_trac = inputdlg({'First y-pixel','First x-pixel','Last x-pixel'},'Add trace',1,{'1','1',num2str(c)});
        if isempty(ans_trac)
            return
        elseif str2double(ans_trac{2})>str2double(ans_trac{3})
            uiwait(msgbox('Operation can not be completed: 1st x > last x','error','modal'));
            return
        end
        
        
        dat=get(t,'data');
        idx2keep= [dat{:,end}];
        dat=dat(idx2keep,:);
        
        numeric=round([str2double(ans_trac{1}),str2double(ans_trac{2}),str2double(ans_trac{3})]);
        dat(size(dat,1)+1,:)={numeric(1),numeric(2),numeric(3),true};
        set(t,'Data',dat,'RowName',1:numel(pt_traces));
        
        apply_table_changes;
    end


    function apply_table_changes(hObject, eventdata)
        %global pt_traces pt_traceLABEL % to be able to delete it.
        % apply changes to uitable
        
        dat=get(t,'data');
        idx2keep= [dat{:,end}];
        dat=dat(idx2keep,:);
        
        try, delete(pt_traces); end
        try, delete(pt_traceLABEL); end
        
        % sort by ascending 1st y-pixel
        firstyat_1=ftrend(1)+[dat{:,1}]'-ftrend([dat{:,2}]);
        
        
        [~,idat]=sort(firstyat_1);
        dat=dat(idat,:);
        
        pt_traces=zeros(1,size(dat,1));
        pt_traceLABEL=zeros(1,size(dat,1));
        hold(H.ax1,'on');
        for it=1:size(dat,1)
            pt_traces(it)=plot(H.ax1,dat{it,2}:dat{it,3},dat{it,1}+ftrend(dat{it,2}:dat{it,3})-ftrend(dat{it,2}),'c--','LineWidth',1);
            %pt_traceLABEL(it)=text(dat{it,2}+10,10+dat{it,1}+ftrend(dat{it,2}),num2str(it),'BackgroundColor',[1 1 .8],'Parent',H.ax1);
            pt_traceLABEL(it)=text(dat{it,2}+10,10+dat{it,1},num2str(it),'BackgroundColor',[1 1 .8],'Parent',H.ax1);
        end
        hold(H.ax1,'off');
        
        traces_visibility;
        set(t,'Data',dat,'RowName',1:numel(pt_traces));
        drawnow
        
    end


end


function digitize_traces(hObject, eventdata)
global H ptrace ptraceSTD pt_traces itodigitize

itodigitize=1:length(pt_traces);
if any(ishandle(ptrace))
    cancel_dig=true;
    %% select traces to be proccesed
    f = dialog('Units','Normalized','Position',[0.8 0.1 0.11 0.7],'Name','Select traces to digitize');
    columnname ='Digitize';
    columnformat = {'logical'};
    columneditable =  [true];
    tdata=false(numel(pt_traces),1); tdata(itodigitize)=true;
    t = uitable('Parent',f,'Units','normalized','Position',...
        [0.0 0.14 1 0.84], 'Data',tdata,...
        'ColumnName', columnname,...
        'ColumnFormat', columnformat,...
        'ColumnEditable', columneditable,...
        'RowName',1:numel(pt_traces));
    
    uicontrol('Style', 'pushbutton','Parent',f,'units','normalized',...
        'String', 'All','TooltipString','Click on all','Position', [0.05 0.075 0.3 0.05],'Callback',@select_tr);
    uicontrol('Style', 'pushbutton','Parent',f,'units','normalized',...
        'String', 'Odd','TooltipString','Click on the odd','Position', [0.35 0.075 0.3 0.05],'Callback',@select_tr);
    uicontrol('Style', 'pushbutton','Parent',f,'units','normalized',...
        'String', 'Even','TooltipString','Click on the even','Position', [0.65 0.075 0.3 0.05],'Callback',@select_tr);
    
    uicontrol('Style', 'pushbutton','Parent',f,'units','normalized',...
        'String', 'Ok','Position', [0.05 0.02 0.35 0.05],'Callback',@select_traces_to_digitize);
    uicontrol('Style', 'pushbutton','Parent',f,'units','normalized',...
        'String', 'Cancel','Position', [0.4 0.02 0.55 0.05],'Callback',@cancel_digitizing);
    %%
    waitfor(f);
    
    if  cancel_dig
        return
    end
    
else
    try
        delete(ptrace)
        delete(ptraceSTD)
    end
    try
        delete(findobj(H.ax1,'Color',[0 .8 1]));
        delete(findobj(H.ax1,'Color',[0 .6 1]));
        delete(findobj(H.ax1,'Color',[1 .7 0]));
        delete(findobj(H.ax1,'Color',[0.3 0.1 1])); % std
    end
    
    
    % create dummy traces update XData YData during digitization.
    ptraceSTD=[];
    ptrace=[];
    bcol=1;col=[0 .6 1];
    hold(H.ax1,'on')
    for i=[itodigitize(:)]'
        ptrace(i)=plot(H.ax1,1,i,'-','color',col,'linewidth',2);
        ptraceSTD(i)=plot(H.ax1,1,i,'-','color',[0.3 0.1 1],'linewidth',2);
        if bcol, bcol=0;col=[0 .8 1]; else bcol=1;col=[0 .6 1]; end
    end
end



% Question
button = questdlg('Do you want to use trace assign information for the Digitization?','Digitize traces','Yes','No','Cancel','No');
if strcmpi(button,'yes')
    digitize_traces_with_assignments;
elseif strcmpi(button,'No')
    digitize_traces_without_assignments;
else
    return
end



%%%%%%%%% functions for the buttons of selection figure.
function select_tr(hObject, eventdata)
   tdata=get(t,'data');
   if strcmpi(get(hObject,'String'), 'All')
    tdata(1:numel(tdata))= ~tdata(1:numel(tdata));
   elseif strcmpi(get(hObject,'String'), 'Odd')
    tdata(1:2:numel(tdata)-1)= ~tdata(1:2:numel(tdata)-1);
   elseif strcmpi(get(hObject,'String'), 'Even')
    tdata(2:2:numel(tdata))= ~tdata(2:2:numel(tdata));
   else
       error('Wrong selection (it should never gets here)')
   end
   set(t,'data',tdata);    
    
end



    function select_traces_to_digitize(hObject, eventdata)
        dat=get(t,'data');
        itodigitize= find(dat);
        cancel_dig=false;
        close(f);
    end
    function cancel_digitizing(hObject, eventdata)
        cancel_dig=true;
        close(f);
    end


end



function digitize_traces_without_assignments(hObject, eventdata)
global H I0 ftrend pt_traces ptrace ptraceSTD S output_message itodigitize

% retrieve values from GUI
%luminance_thershold=str2double(get(H.edit_luminance,'string'));
over_under=str2num(get(H.edit_offset,'string')); %#ok<ST2NM>

[rows,cols]=size(I0);

fX=ftrend(cell2mat(cellfun(@(v) v(1),get(pt_traces,'Xdata'),'UniformOutput',false)));
Y=cell2mat(cellfun(@(v) v(1),get(pt_traces,'Ydata'),'UniformOutput',false));
meanOffset=mode(abs(diff(Y)));

Bbox=cell2mat({S.BoundingBox}');
itick=[S.ID]==1;
itrace=[S.ID]==0;

C=[Bbox(:,2)+Bbox(:,4)/2,Bbox(:,1)+Bbox(:,3)/2];
Bbox=[floor(Bbox(:,2)),ceil(Bbox(:,2)+Bbox(:,4))];
BboxTick=Bbox(itick,:);
Bbox=Bbox(itrace,:);
Ctick=C(itick,:);
C=C(itrace,:);

Stick=S(itick);
Strace=S(itrace);

hold(H.ax1,'on')
output_message{end+1}='Digitizing, please wait...';
set(H.output_mess,'String',output_message,'Value',length(output_message)); drawnow

set(H.axwait,'Visible','on');
for i=[itodigitize(:)]' %1:numel(pt_traces)
    
    % update axwait
    temp=find(i==itodigitize)/numel(itodigitize); %  oxi I ALLA INDX(I)
    h=pie(H.axwait,[1-temp+eps, temp],{'',''});
    set(h(3),'EdgeColor','none');
    set(h(1),'EdgeColor','None','FaceColor',[0.3 0.3 0.3]);
    set(h(3),'FaceColor',[1 1 1]);
    text(0,0,[num2str(find(i==itodigitize)) '/' num2str(numel(itodigitize))],...
        'HorizontalAlignment','Center','FontWeight','bold',...
        'Color','w','BackgroundColor',[0.5 0.5 0.5],'Parent',H.axwait);
    drawnow
    %% digitize
    
    % prepare stripes
    
    zerotrace_i= Y(i)-fX(i)+ftrend(C(:,2));
    itrace_i=C(:,1) > over_under(1)*meanOffset+zerotrace_i &...
        C(:,1) < over_under(2)*meanOffset+zerotrace_i;
    zerotick_i=Y(i)-fX(i)+ftrend(Ctick(:,2));
    
    if  strcmpi(get(H.timemarkpos,'State'),'off') % time marks above the trace
        itick_i=Ctick(:,1) > -abs(over_under(1))*meanOffset+zerotick_i-meanOffset/2 &...
            Ctick(:,1) < zerotick_i;
    elseif strcmpi(get(H.timemarkpos,'State'),'on')  % time marks bellow the trace
        itick_i=Ctick(:,1) < abs(over_under(2))*meanOffset+zerotick_i+meanOffset/2 &...
            Ctick(:,1) > zerotick_i;
    else % It should never go to else
        error('Problem with time marks button status')
    end
    
    
    rstart= max(1,min([Bbox(itrace_i,1);BboxTick(itick_i,1)]));
    rend=min(size(I0,1),max([Bbox(itrace_i,2); BboxTick(itick_i,2)]));
    
    buff=rend-rstart+1;
    
    
    Itemp=I0(rstart:rend,:);
    
    temp=false(size(Itemp));
    tempNULL=temp;
    
    [i1,j1]=ind2sub([rows,cols],cell2mat({Strace(itrace_i).PixelIdxList}'));
    try
        iok=i1>=rstart & i1<=rend;
    catch
        warning('Possible problem during digitization. of trace# %d. No assigned objects were found.',i)
        output_message{end}=['skipping ' num2str(find(i==itodigitize)) '/' num2str(numel(itodigitize))];
        set(H.output_mess,'String',output_message,'Value',length(output_message)); drawnow
        continue
    end
    temp(sub2ind(size(temp),i1(iok)-rstart+1,j1(iok)))=true;
    
    [i1,j1]=ind2sub([rows,cols],cell2mat({Stick(itick_i).PixelIdxList}'));
    iok=i1>=rstart & i1<=rend;
    tempNULL(sub2ind(size(tempNULL),i1(iok)-rstart+1,j1(iok)))=true;
    
    x=round(get(pt_traces(i),'XDATA'));
    y=round(get(pt_traces(i),'YDATA'))-rstart+1;
    if (y(1))<=0
        y=y -y(1)+1;
    end
    
    
    stripe=zeros(3*buff,numel(x),'uint8');
    bstripe=false(3*buff,numel(x));
    bstripe_tick=false(3*buff,numel(x));
    
    
    for ix=1:numel(x)
        if x(ix)>0 && x(ix)<size(Itemp,2);
            stripe(max(1,y(ix)+ [1:buff]),ix)=Itemp(:,x(ix));
            bstripe(max(1,y(ix)+ [1:buff]),ix)= temp(:,x(ix));
            bstripe_tick(max(1,y(ix)+ [1:buff]),ix)= tempNULL(:,x(ix));
        else
            warning('Possible problem during digitization. report that: x(ix)=%d (it should be between 1 and %d), trace# %d',x(ix),size(Itemp,2),i)
        end
    end
    
    
    output_message{end}=['Digitizing ' num2str(find(i==itodigitize)) '/' num2str(numel(itodigitize)) ', please wait...'];
    set(H.output_mess,'String',output_message,'Value',length(output_message)); drawnow
    
    if str2double(get(H.edit_tick_xlength,'String'))>0
        [YDATA,YDATASTD]=digitize_trace_and_tickmarks(stripe,stripe,bstripe,bstripe_tick); % stripe and stripe NULL are the same
    else
        [YDATA,YDATASTD]=digitize_trace_without_tickmarks(stripe,bstripe);
    end
    
    XDATA=x; % correct for real starting point
    YDATA=YDATA-y + rstart - 1;
    YDATASTD=YDATASTD+YDATA;
    
    set(ptrace(i),'XData',XDATA,'YData',YDATA);
    set(ptraceSTD(i),'XData',XDATA,'YData',YDATASTD); %std
    
end
hold(H.ax1,'off')

output_message{end+1}='Digitization finished.';
set(H.output_mess,'String',output_message,'Value',length(output_message)); drawnow
output_message{end+1}='Ready.';
set(H.output_mess,'String',output_message,'Value',length(output_message)); drawnow
cla(H.axwait); set(H.axwait,'Visible','off');


end




function digitize_traces_with_assignments(hObject, eventdata)
global H I0 pt_traces ptrace ptraceSTD S output_message itodigitize


[rows,cols]=size(I0);
Bbox=cell2mat({S.BoundingBox}');
itick=[S.ID]==1;
itrace=[S.ID]==0;
Bbox=[floor(Bbox(:,2)),ceil(Bbox(:,2)+Bbox(:,4))];
BboxTick=Bbox(itick,:);
Bbox=Bbox(itrace,:);

Stick=S(itick);
Strace=S(itrace);



hold(H.ax1,'on')
output_message{end+1}='Digitizing, please wait...';
set(H.output_mess,'String',output_message,'Value',length(output_message)); drawnow

set(H.axwait,'Visible','on');
for i=[itodigitize(:)]' %1:numel(pt_traces)
    
    % update axwait
    
    temp=find(i==itodigitize)/numel(itodigitize);  % oxi I ALLA INDX(I)
    h=pie(H.axwait,[1-temp+eps, temp],{'',''});
    set(h(3),'EdgeColor','none');
    set(h(1),'EdgeColor','None','FaceColor',[0.3 0.3 0.3]);
    set(h(3),'FaceColor',[1 1 1]);
    text(0,0,[num2str(find(i==itodigitize)) '/' num2str(numel(itodigitize))],...
        'HorizontalAlignment','Center','FontWeight','bold',...
        'Color','w','BackgroundColor',[0.5 0.5 0.5],'Parent',H.axwait);
    drawnow
    %% digitize
    
    % prepare stripes
    itrace_i=find(cellfun(@(x)any(x==i),{Strace.TraceNum}));
    itick_i=find(cellfun(@(x)any(x==i),{Stick.TraceNum}));
    
    rstart= max(1,min([Bbox(itrace_i,1);BboxTick(itick_i,1)]));
    rend=min(size(I0,2),max([Bbox(itrace_i,2); BboxTick(itick_i,2)]));
    
    buff=rend-rstart+1;
    
    Itemp=I0(rstart:rend,:);
    
    temp=false(size(Itemp));
    tempNULL=temp;
    
    [i1,j1]=ind2sub([rows,cols],cell2mat({Strace(itrace_i).PixelIdxList}'));
    iok=i1>=rstart & i1<=rend;
    temp(sub2ind(size(temp),i1(iok)-rstart+1,j1(iok)))=true;
    
    [i1,j1]=ind2sub([rows,cols],cell2mat({Stick(itick_i).PixelIdxList}'));
    iok=i1>=rstart & i1<=rend;
    tempNULL(sub2ind(size(tempNULL),i1(iok)-rstart+1,j1(iok)))=true;
    
    x=round(get(pt_traces(i),'XDATA'));
    y=round(get(pt_traces(i),'YDATA'))-rstart+1;
    y(y<1)=1;
    
    stripe=zeros(3*buff,numel(x),'uint8');
    bstripe=false(3*buff,numel(x));
    bstripe_tick=false(3*buff,numel(x));
    
    
    for ix=1:numel(x)
        if x(ix)>0 && x(ix)<size(Itemp,2);
            stripe(max(1,y(ix)+ [1:buff]),ix)=Itemp(:,x(ix));
            bstripe(max(1,y(ix)+ [1:buff]),ix)= temp(:,x(ix));
            bstripe_tick(max(1,y(ix)+ [1:buff]),ix)= tempNULL(:,x(ix));
        else
            warning('Possible problem during digitization. report that: x(ix)=%d (it should be between 1 and %d), trace# %d',x(ix),size(Itemp,2),i)
        end
    end
    
    output_message{end}=['Digitizing ' num2str(fond(i==itodigitize)) '/' num2str(numel(itodigitize)) ', please wait...'];
    set(H.output_mess,'String',output_message,'Value',length(output_message)); drawnow
    
    
    if str2double(get(H.edit_tick_xlength,'String'))>0
        [YDATA,YDATASTD]=digitize_trace_and_tickmarks(stripe,stripe,bstripe,bstripe_tick); % stripe and stripe NULL are the same
    else
        [YDATA,YDATASTD]=digitize_trace_without_tickmarks(stripe,bstripe);
    end
    
    XDATA=x; % correct for real starting point
    YDATA=YDATA-y + rstart - 1;
    YDATASTD=YDATASTD+YDATA;
    
    set(ptrace(i),'XData',XDATA,'YData',YDATA);
    set(ptraceSTD(i),'XData',XDATA,'YData',YDATASTD);
    
end
hold(H.ax1,'off')

output_message{end+1}='Digitization finished.';
set(H.output_mess,'String',output_message,'Value',length(output_message)); drawnow

output_message{end+1}='Ready.';
set(H.output_mess,'String',output_message,'Value',length(output_message)); drawnow

cla(H.axwait); set(H.axwait,'Visible','off');


end






%%

function correct_trace(hObject, eventdata)
global H I0 pt_traces ptrace ptraceSTD ftrend
% initialize
BWstripe=[];
BWstripeNULL=[];
BWS=[];
number_of_traces=numel(pt_traces);

% Select trace with mouse
h=msgbox('Click with mouse anywhere on the trace you want to correct.','Correct trace','help',[],'WindowStyle','modal');
waitfor(h);

[xc,yc]=ginput(1);

% Find the trace number
d=zeros(number_of_traces,1);
for i=1:number_of_traces
    d(i)=min( (get(pt_traces(i),'XDATA')-xc).^2 + (get(pt_traces(i),'YDATA')-yc).^2 );
end
[~,iTRACE]=min(d);
x=round(get(pt_traces(iTRACE),'XDATA'));

position=[max(1,xc-300) max(1,yc-70) 600 140];
position(3)=min(size(I0,2)-position(1),position(3));
position(4)=min(size(I0,1)-position(2),position(4));



% create rectangle to get the problematic patch
hrec = imrect(gca,position);
api = iptgetapi(hrec);
fcn = makeConstrainToRectFcn('imrect',get(gca,'Xlim'),get(gca,'YLim'));
api.setDragConstraintFcn(fcn);
position=wait(hrec);
delete(hrec);
position=round(position);
stripe=imcrop(I0,position);
[r,c]=size(stripe);

xpatch=position(1)+[0:position(3)];
xpatch=xpatch(xpatch>=x(1) & xpatch<=x(end));
ypatch=position(2)+[0:position(4)];



%% Launch GUI for single trace analysis and digitization
h1stripe.f=figure('Color','w','WindowStyle','normal','Name',['Edit trace ' num2str(iTRACE)] ,'NumberTitle','Off',...
    'Menubar','none','ToolBar','figure','Units','Normalized','Position',[0.1 0.5 0.8 0.3]);

% modify tool bar
temp= findall(findall(h1stripe.f,'Type','uitoolbar'));
delete(temp([2:7 9 13 16 17]));
% % Reorder tools
% set(temp(1),'Children',[temp(4:end-1);temp(2:3);temp(end)])

% add some tools
bColorSchemeS=uitoggletool(temp(1),'Tag','Change colors','Cdata',imread('ColorScheme.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','Change classification colors',...
    'HandleVisibility','off','ClickedCallback',@update_classplotS);

uipushtool(temp(1),'Tag','Select region mirrored','Cdata',imread('contrast-icon.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','Adjust contrast',...
    'HandleVisibility','on','ClickedCallback',@adjust_contrastS);

uipushtool(temp(1),'Tag','Select region mirrored','Cdata',imread('select_MirrorS.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','Draw a symmetric region',...
    'HandleVisibility','on','ClickedCallback',@select_region_mirrorS);

uipushtool(temp(1),'Tag','Remove region','Cdata',imread('removeS.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','Draw a region to remove',...
    'HandleVisibility','on','ClickedCallback',@remove_regionS);

uipushtool(temp(1),'Tag','Seperate','Cdata',imread('seperateS.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','Draw a seperation border',...
    'HandleVisibility','on','ClickedCallback',@remove_along_pathS);

htundo=uipushtool(temp(1),'Tag','Undo last','Cdata',imread('undo.jpeg'),...
    'Separator','on','TooltipString','Undo last action',...
    'HandleVisibility','on','Enable','off','ClickedCallback',@UNDO);

uitoggletool(temp(1),'Tag','Show clasification','Cdata',imread('show_Class.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','Calculate and show classification',...
    'HandleVisibility','on','ClickedCallback',@SeperateS,'State','off');
uipushtool(temp(1),'Tag','s2Reject','Cdata',imread('reject.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','Select object to ckassify as rejected',...
    'HandleVisibility','on','ClickedCallback',@modify_classification,'Enable','off');
uipushtool(temp(1),'Tag','s2Timemark','Cdata',imread('timemark.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','Select object to ckassify as timemark',...
    'HandleVisibility','on','ClickedCallback',@modify_classification,'Enable','off');
uipushtool(temp(1),'Tag','s2Trace','Cdata',imread('trace.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','Select object to ckassify as trace',...
    'HandleVisibility','on','ClickedCallback',@modify_classification,'Enable','off');
hbut_draw=uipushtool(temp(1),'Tag','drawmask','Cdata',zeros(16,16,3,'uint8'),... %imread('drawmask.png','BackgroundColor',[1 1 1])
    'Separator','on','TooltipString','Click to create a mask for the current trace (currently inactive)',...
    'HandleVisibility','on','ClickedCallback',@drawmask,'Enable','off');
redbt=zeros(16,16,3,'uint8'); redbt(:,:,1)=255;
uipushtool(temp(1),'Tag','s2Trace','Cdata',redbt,...
    'Separator','on','TooltipString','Recalculate classification',...
    'HandleVisibility','on','ClickedCallback',@CaLLClassify_from_scratchS,'Enable','off');
clear redbt;

hbdigitize_single=uipushtool(temp(1),'Tag','Digitize trace','Cdata',imread('digitize1.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','Digitize trace',...
    'HandleVisibility','on','ClickedCallback',@Digitize_Single,'Enable','off');


h1stripe.tbar=findall(findall(h1stripe.f,'Type','uitoolbar'));

%
% 1   'FigureToolBar'
% 2   'Digitize trace'

% 3    s2Trace
% 4    s2Timemark
% 5    s2Reject

% 6    'Show clasification'

% 7    'Undo last'
% 8    'Seperate'
% 9    'Remove region'
% 10   'Select region mirrored'
% 11   'Select region'

% 12   ''
% 13   'Exploration.DataCursor'
% 14   'Exploration.Pan'
% 15   'Exploration.ZoomOut'
% 16   'Exploration.ZoomIn'
% 17   'Standard.PrintFigure'
% 18   'Standard.SaveFigure'



h1stripe.axI=axes('Units','Normalized','Position',[0.05 0.2 0.94 0.79],...
    'Xtick',[],'Ytick',[],'box','on','Parent',h1stripe.f);

h1stripe.applyb=uicontrol('Style', 'pushbutton','Parent',h1stripe.f,'units','normalized',...
    'String', 'Apply','Position', [0.81 0.001 0.07 0.07],'Callback',@Apply_to_main);
h1stripe.close=uicontrol('Style', 'pushbutton','Parent',h1stripe.f,'units','normalized',...
    'String', 'Close','Position', [0.881 .001 0.07 0.07],'Callback',@Closethefigure);

SCLA=[];

% plot trace
image(xpatch,ypatch,stripe); colormap(gray(256));





    function update_plotS(hObject, eventdata)
        xylimits=axis;
        cla
        imagesc(xpatch,ypatch,stripe,'Parent',h1stripe.axI),colormap(h1stripe.axI,gray(256));
        axis(xylimits);
    end

    function remove_regionS(hObject, eventdata)
        global stripe0
        
        % fixes the bug(?) with imfreehand... PETROS
        set(h1stripe.f,'WindowButtonDownFcn','')
        set(h1stripe.f,'WindowButtonMotionFcn','')
        set(h1stripe.f,'WindowButtonUpFcn','')
        set(h1stripe.f,'WindowKeyPressFcn','')
        set(h1stripe.f,'WindowKeyReleaseFcn','')
        set(h1stripe.f,'WindowScrollWheelFcn','')
        
        h=imfreehand(h1stripe.axI);
        h.Deletable = false;
        stripe0=stripe; % save an undo copy
        stripe(h.createMask)=0;
        update_plotS;
        set(htundo,'Enable','on');
    end

    function select_regionS(hObject, eventdata)
        global stripe0
        
        % fixes the bug(?) with imfreehand... PETROS
        set(h1stripe.f,'WindowButtonDownFcn','')
        set(h1stripe.f,'WindowButtonMotionFcn','')
        set(h1stripe.f,'WindowButtonUpFcn','')
        set(h1stripe.f,'WindowKeyPressFcn','')
        set(h1stripe.f,'WindowKeyReleaseFcn','')
        set(h1stripe.f,'WindowScrollWheelFcn','')
        
        h=imfreehand(h1stripe.axI);
        h.Deletable = false;
        stripe0=stripe; % save an undo copy
        stripe(~[h.createMask])=0;
        update_plotS
        set(htundo,'Enable','on');
    end

    function select_region_mirrorS(hObject, eventdata)
        global stripe0
        
        % fixes the bug(?) with imfreehand... PETROS
        set(h1stripe.f,'WindowButtonDownFcn','')
        set(h1stripe.f,'WindowButtonMotionFcn','')
        set(h1stripe.f,'WindowButtonUpFcn','')
        set(h1stripe.f,'WindowKeyPressFcn','')
        set(h1stripe.f,'WindowKeyReleaseFcn','')
        set(h1stripe.f,'WindowScrollWheelFcn','')
        
        
        h=imfreehand(h1stripe.axI,'Closed',false);
        h.Deletable = false;
        pos=h.getPosition;
        delete(h);
        [xx,iun]=unique(pos(:,1));
        yy=pos(iun,2);
        xq=linspace(xpatch(1),xpatch(end),min(size(xx,1),12))';
        yq=interp1(xx,yy,xq,'linear','extrap');
        pos=[xq yq;flipud([xq [ypatch(1)-yq+ypatch(end)]])];
        h=impoly(h1stripe.axI,pos);
        h.Deletable = false;
        wait(h);
        
        stripe0=stripe; % save an undo copy
        stripe(~[h.createMask])=0;
        update_plotS;
        set(htundo,'Enable','on');
    end


    function remove_along_pathS(hObject, eventdata)
        global stripe0
        stripe0=stripe;
        % fixes the bug(?) with imfreehand... PETROS
        set(h1stripe.f,'WindowButtonDownFcn','')
        set(h1stripe.f,'WindowButtonMotionFcn','')
        set(h1stripe.f,'WindowButtonUpFcn','')
        set(h1stripe.f,'WindowKeyPressFcn','')
        set(h1stripe.f,'WindowKeyReleaseFcn','')
        set(h1stripe.f,'WindowScrollWheelFcn','')
        
        
        hfh=imfreehand(h1stripe.axI,'closed',false);
        hfh.Deletable = false;
        pos=hfh.getPosition;
        [cx,cy,~] = improfile(xpatch,ypatch,stripe,pos(:,1),pos(:,2));
        linearInd = sub2ind([r,c], min(r,max(1,round(cy-ypatch(1)+1))),min(c,max(1,round(cx-xpatch(1)+1))));
        stripe(linearInd)=0;
        delete(hfh);
        update_plotS
        set(htundo,'Enable','on');
    end



    function UNDO(hObject, eventdata)
        global stripe0
        stripe=stripe0;
        update_plotS;
        drawnow;
        set(htundo,'Enable','off');
    end


    function adjust_contrastS(hObject, eventdata)
        global stripe0
        stripe0=stripe;
        hFig = figure('Color','w','NumberTitle','off','Toolbar','none',...
            'Menubar','none','Visible','off','closerequestfcn','','Name',['Trace ' num2str(iTRACE)]);
        hIm = imshow(stripe);
        hSP = imscrollpanel(hFig,hIm);
        set(hSP,'Units','normalized',...
            'Position',[0.0 0.05 1 .95])
        hMagBox = immagbox(hFig,hIm);
        pos = get(hMagBox,'Position');
        set(hMagBox,'Position',[0 0 pos(3) pos(4)])
        %imoverview(hIm0);
        hImCon=imcontrast(hIm);
        set(hFig,'Visible','on')
        waitfor(hImCon);
        stripe=get(hIm,'Cdata');
        update_plotS;
        drawnow
        delete(hFig);
        % enable undo
        set(htundo,'Enable','on');
    end






    function SeperateS(hObject, eventdata)
        % Go to classification mode, if 1st time create classification
        
        if strcmpi(get(hObject,'State'),'ON')
            
            %        set([h1stripe.Bremove_region,h1stripe.Bselect_region,h1stripe.Bselect_region_mirror,h1stripe.BSeperate,h1stripe.BUndo],'Enable','off')
            set(h1stripe.tbar([2 9:12]),'Enable','off');
            set(h1stripe.tbar([3:7]),'Enable','on');
            
            
            if isempty(get(hObject,'UserData'))
                Classify_from_scratchS;
                set(hObject,'UserData',1)
            else
                update_classplotS;
            end
            
        else
            
            update_plotS;
            set(h1stripe.tbar([2 9:12]),'Enable','on');
            set(h1stripe.tbar([3:7]),'Enable','off');
        end
        set(hbut_draw,'Enable','off'); % not ready yet. 
    end

    function CaLLClassify_from_scratchS(hObject, eventdata)
        
        button = questdlg({'Are you sure you want to recalculate classification?';'Current classification will be lost!'},'Confirmation','Yes','No','No');
        if strcmpi(button,'NO')
            return
        else
            Classify_from_scratchS;
        end
    end

    function Classify_from_scratchS(BW)
        % create binary and calculate classification. Previous values are lost.
        global tick_length_lim
        
        level=str2double(get(H.edit_luminance,'string'));
        tick_length=str2double(get(H.edit_tick_xlength,'String'));
        if isnan(tick_length)
            errordlg('Invalid length of time marks!','Error!')
            return
        end
        
        sh=smooth(sum(stripe,2));
        [~,imax]=max(sh);
        
        if nargin==1
            BWS=BW;
        else
            BWS=im2bw(stripe,level/100);
        end
        % calculate initial classification
        SCLA=regionprops(BWS,{'Centroid','BoundingBox','PixelIdxList'});
        
        time_length=cell2mat({SCLA.BoundingBox}');
        time_length=time_length(:,3)';% tale width;
        
        temp1=cell2mat({SCLA.Centroid}'); temp1=temp1(:,2)';
        %idRej=time_length-tick_length>5 | (abs(tick_length-time_length)<=5  & temp1>imax);
        
        if tick_length>0
            if  strcmpi(get(H.timemarkpos,'State'),'off') % time marks above the trace
                idTick=abs(time_length-tick_length)<=tick_length_lim*tick_length & temp1<=imax;
            elseif strcmpi(get(H.timemarkpos,'State'),'on')  % time marks bellow the trace
                idTick=abs(time_length-tick_length)<=tick_length_lim*tick_length & temp1>=imax;
            else % It should never go to else
                error('Problem with time marks button status')
            end
        else
            idTick=[];
        end
        
        
        idTrace=time_length-tick_length>tick_length_lim*tick_length;
        
        % add classification
        [SCLA(idTrace).ID]=deal(0);
        [SCLA(idTick).ID]=deal(1);
        idRej=cellfun(@(xvar) isempty(xvar),{SCLA.ID});
        [SCLA(idRej).ID]=deal(-1);
        %             rejected_indx=cell2mat({SCLA(idRej).PixelIdxList}');
        %             tick_indx=cell2mat({SCLA(idTick).PixelIdxList}');
        %             main_indx=cell2mat({SCLA(idTrace).PixelIdxList}');
        %
        irej=cell2mat({SCLA([SCLA.ID]==-1).PixelIdxList}');
        itick=cell2mat({SCLA([SCLA.ID]==1).PixelIdxList}');
        itrace=cell2mat({SCLA([SCLA.ID]==0).PixelIdxList}');
        
        update_classplotS(itrace,itick,irej);
        
        %% create outputs
        BWstripe=false(r,c); BWstripe(itrace)=true;
        BWstripeNULL=false(r,c); BWstripeNULL(itick)=true;

        set(hbdigitize_single,'Enable','on')
    end


    function drawmask(hObject, eventdata)
        
        %         % First try this
        %         BW2= imerode(BWS,strel('line',6,0));
        %         BW2 = BWS & ~imdilate(bwareaopen(BW2,60),strel('line',10,90));
        %
        %
        %         % then this one
        %         param1=40; % this can change...
        %         % create segments
        %         BW2= bwmorph(bwmorph(BWS,'tophat'),'clean',inf);
        %         BW2=imdilate(BW2,strel('disk', 6,0));
        %         BW2 = bwareaopen(BW2,param1);
        %         BW3=BW2;
        %         BW2= BWS & ~BW2;
        %         BW2 = bwareaopen(BW2,param1);
        %         BW3=imdilate(BW3,strel('diamond', 3));
        %
        %         Target=stripe;
        %         Target(~BW3)=0;
        %         figure;imshow([BW2;BW3])
        %
        %         tol=0.1;
        %         yyy=digitize_region(double(Target),tol);
        %
        %         iok=~isnan(yyy);
        %         xxx=x(iok); yyy=yyy(iok);
        %
        %         xi=x(1):4:x(end);
        %         yi=interp1(xxx,yyy,xi);
        %         hpoly = impoly(gca, [xi;yi]','closed',false,'Deletable',false);
        
        
        hmfree = imfreehand(gca,'closed',false);
        hmfree.Deletable=false;
        pos=double(hmfree.getPosition);
        delete(hmfree);
        pxfree=linspace(min(pos(:,1)),max(pos(:,1)),numel(min(pos(:,1)):max(pos(:,1))),25);
        
        hpoly = impoly(gca, pos,'closed',false);
        hpoly.Deletable=false;
        pos=double(round(wait(hpoly)));
        delete(hpoly);
        
        answer = inputdlg('Enter thickness of traced line (an integer>0. Enter 0 to cancel and return to manual classification)',...
            'Traced line thickness',1,{'2'});
        answer = double(round(str2double(answer)));
        if answer<=0
            return
        end
        
        BW=0*BWS;
        [cx,cy,~] = improfile(BWS,pos(:,1),pos(:,2));
        linearInd = sub2ind([r,c], min(r,max(1,round(cy-ypatch(1)+1))),min(c,max(1,round(cx-xpatch(1)+1))));
        BW(linearInd)=1;
        BW=imdilate(BW,strel('disk', answer,0));
        BWS=BW & BWS;
        
        Classify_from_scratchS(BW)
        
        %imshow(BW);
        
        % temp=imcomplement(I01(1:end-1,1:end-1));
        % temp(~BW2)= 255;
        % imshow(temp)
        % title('top-bottom traces')
        % axis on
        % set(gca,'Xtick',[],'Ytick',[])
        
        
    end


    function modify_classification(hObject, eventdata)
        
        tag=get(hObject,'tag');
        if strcmp(tag,'s2Trace')
            id=0;
        elseif strcmp(tag,'s2Reject')
            id=-1;
        elseif strcmp(tag,'s2Timemark')
            id=1;
        else
            error('Problem in modify classification, single trace')
        end
        
        [colSub,rowSub,butt]=ginput(1);
        while butt==1
            linearInd = sub2ind([r,c], min(r,round(max(1,rowSub-ypatch(1)+1))),round(min(c,max(1,colSub-xpatch(1)+1))));
            for iter=1:length(SCLA)
                if any(linearInd==SCLA(iter).PixelIdxList)
                    SCLA(iter).ID=id;
                    update_classplotS;
                    break;
                end
            end
            [colSub,rowSub,butt]=ginput(1);
        end
        
        irej=cell2mat({SCLA([SCLA.ID]==-1).PixelIdxList}');
        itick=cell2mat({SCLA([SCLA.ID]==1).PixelIdxList}');
        itrace=cell2mat({SCLA([SCLA.ID]==0).PixelIdxList}');
        
        %% modify plot and outputs
        update_classplotS(itrace,itick,irej);
        %The following can be accelerated in a future version by updating only what is changed
        BWstripe=false(r,c); BWstripe(itrace)=true;
        BWstripeNULL=false(r,c); BWstripeNULL(itick)=true;
        
    end


    function update_classplotS(itrace,itick,irej)
        
        if nargin<3
            irej=cell2mat({SCLA([SCLA.ID]==-1).PixelIdxList}');
            itick=cell2mat({SCLA([SCLA.ID]==1).PixelIdxList}');
            itrace=cell2mat({SCLA([SCLA.ID]==0).PixelIdxList}');
        end
        
        
        G=zeros(r,c,'uint8'); R=G; B=G;
        
        if strcmpi(get(bColorSchemeS,'state'),'off')
            R([irej;itrace])=255;
            G([itick; itrace])=255;
            B(itrace)=255;
        else
            R([irej;itrace])=255;
            B([itick;itrace])=255;
            G(itick)=220;
            G(itrace)=255;
        end
        
        
        stripeRGB=zeros(r,c,3,'uint8');
        stripeRGB(:,:,1)=R; stripeRGB(:,:,2)=G; stripeRGB(:,:,3)=B;
        
        %         xl=get(h1stripe.axI,'xlim');
        %         yl=get(h1stripe.axI,'ylim');
        
        hold(h1stripe.axI,'off')
        imagesc(xpatch,ypatch,stripeRGB,'parent',h1stripe.axI)
        %        hold(h1stripe.axI,'on')
        %        %plot(1:c,repmat(imax,1,c),'y')
        %         plot(h1stripe.axI,200,20,'rsq','MarkerFaceColor','r','MarkerSize',10),text(600,20,'Rejected objects','Color','w')
        %         plot(h1stripe.axI,200,50,'gsq','MarkerFaceColor','g','MarkerSize',10),text(600,50,'Time-marks','Color','w')
        %         plot(h1stripe.axI,200,80,'wsq','MarkerFaceColor','w','MarkerSize',10),text(600,80,'Main trace','Color','w')
        %         set(h1stripe.axI,'Xlim',xl,'Ylim',yl);
        %        hold(h1stripe.axI,'off')
        drawnow
    end





    function Digitize_Single(hObject, eventdata)
        global output_message %BWstripe BWstripeNULL
        global pt_single pt_singleSTD
        
        try delete(pt_single), end
        
        % update user
        output_message{end+1}=['Digitizing single trace: '  num2str(iTRACE) ', please wait...'];
        set(H.output_mess,'String',output_message,'Value',length(output_message)); drawnow
        
        % digitize
        [yy,yySTD]=digitize_trace_and_tickmarks(stripe,stripe,BWstripe,BWstripeNULL);
        
        % for patch
        yy=yy+min(ypatch);
        yySTD=yySTD+yy;
        
        % plot at current gui
        hold(h1stripe.axI,'on')
        pt_single=plot(h1stripe.axI,xpatch,yy,'-','color',[1 .7 0],'linewidth',2);
        pt_singleSTD=plot(h1stripe.axI,xpatch,yySTD,'-','color',[0.3 .1 1],'linewidth',2);
        
        
        hold(h1stripe.axI,'off')
        
        % update user
        output_message{end+1}='Ready';
        set(H.output_mess,'String',output_message,'Value',length(output_message)); drawnow
    end

    function Apply_to_main(hObject, eventdata)
        global pt_single pt_singleSTD
        yy=get(pt_single,'YDATA');
        yySTD=get(pt_singleSTD,'YDATA');
        
        
        button = questdlg({['Click at "Skip NaNs" if you want to skip NaN values ',...
            'returned from the digitization. If you click at "Include NaNs" then NaNs will be included.']},...
            'NaN numbers','Skip NaNs','Include NaNs','Skip NaNs');
        if strcmpi(button,'Skip NaNs')
            %replace nans in yy and yySTD with the current value of the trace
            notanan=~isnan(yy);
            yy=yy(notanan);
            yySTD=yySTD(notanan);
            xpatch=xpatch(notanan);
        end
        
        ptraceSTD_EXISTS=true;
        try
         yitraceSTD=get(ptraceSTD(iTRACE),'YData');
        catch
         ptraceSTD_EXISTS=false;
         errordlg('Could not find handles for digitized traces STD. If this file is from an older version of DigitSeis without this feature, ignore this message');
        end
            
        yitrace=get(ptrace(iTRACE),'YData');
        [~,iok,iokxpatch] = intersect(x,xpatch);
        
        yitrace(iok)=yy(iokxpatch);%+ftrend(xpatch(iokxpatch))';
        % update traces
        set(ptrace(iTRACE),'XData',x,'YData',yitrace,'color',[1 .7 0])
        
        if ptraceSTD_EXISTS
            yitraceSTD(iok)=yySTD(iokxpatch);
            set(ptraceSTD(iTRACE),'XData',x,'YData',yitraceSTD,'color',[.3 .1 1])
        end
        
    end


    function Closethefigure(hObject, eventdata)
        
        close(h1stripe.f);
    end

end








%%

function load_analysis(hObject, eventdata)
global H HIM I0 HIMRGB BW ptrace ptraceSTD pt_traces pt_traceLABEL Time ftrend ftrend_tick S output_message  sumI ww pt_start_time pt_end_time p_tick_1st p_tick_last hresult_time_marks


[filename, pathname]=uigetfile({'*.mat','mat files';...
    '*.*','All Files' },'Select analysis file');
if isequal(filename,0)
    return
end
close(gcf); % close old one,



hmsg = dialog('Units','Normalized','Position',[0.5 0.5 0.25 0.1],'Name','Loading saved analysis');
uicontrol('Parent',hmsg,...
    'Style','text','HorizontalAlignment','center',...
    'Units','Normalized','Position',[0.01 .25 0.9 0.5],...
    'String','Loading data, Please wait...','FontSize',12);
pause(2)
close(hmsg)
disp('Loading data. This can take some time, please wait...')
%load everything
load(fullfile(pathname,filename));

set(H.f1,'Visible','off')
% modify tool bar
temp= findall(findall(H.f1,'Type','uitoolbar'));
%    ' 1'     'FigureToolBar'
%     ' 2'    'Plottools.PlottoolsOn'
%     ' 3'    'Plottools.PlottoolsOff'
%     ' 4'    'Annotation.InsertLegend'
%     ' 5'    'Annotation.InsertColorbar'
%     ' 6'    'DataManager.Linking'
%     ' 7'    'Exploration.Brushing'
%     ' 8'    'Exploration.DataCursor'
%     ' 9'    'Exploration.Rotate'
%     '10'    'Exploration.Pan'
%     '11'    'Exploration.ZoomOut'
%     '12'    'Exploration.ZoomIn'
%     '13'    'Standard.EditPlot'
%     '14'    'Standard.PrintFigure'
%     '15'    'Standard.SaveFigure'
%     '16'    'Standard.FileOpen'
%     '17'    'Standard.NewFigure'
%     '18'    ''

set(temp(15),'ClickedCallback',@Saveresults,'TooltipString','Save resutls')



delete(temp([2:7 9 13 17]));
uipushtool(temp(1),'Tag','Reload image from file','Cdata',imread('reload.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','Reload image from file',...
    'HandleVisibility','on','ClickedCallback',@Load_Image);

uipushtool(temp(1),'Tag','View and edit image file','Cdata',imread('imtool.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','View info and edit image with imtool',...
    'HandleVisibility','on','ClickedCallback',@viewimage);

temp= findall(findall(H.f1,'Type','uitoolbar'));
set(temp(end),'ClickedCallback',@Browse_and_Load)

% Reorder tools
set(temp(1),'Children',[temp(4:end-2);temp(2:3);temp(end)])

uipushtool(temp(1),'Tag','Load existing analysis','Cdata',imread('load_analysis.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','Load existing analysis from file',...
    'HandleVisibility','on','ClickedCallback',@load_analysis);

% add some tools
uipushtool(temp(1),'Tag','Show whole seismogram','Cdata',imread('whole_seismogram.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','Show whole seismogram',...
    'HandleVisibility','on','ClickedCallback',@zoom2seismogram);

uipushtool(temp(1),'Tag','Crop Image','Cdata',imread('crop.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','Crop image',...
    'HandleVisibility','on','ClickedCallback',@crop_image);
uipushtool(temp(1),'Tag','Adjust contrast','Cdata',imread('contrast-icon.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','Adjust contrast',...
    'HandleVisibility','on','ClickedCallback',@adjust_contrast);

uipushtool(temp(1),'Tag','Remove background','Cdata',imread('Removebackground.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','Click remove lare background stains-colorization',...
    'HandleVisibility','on','ClickedCallback',@remove_background_withGAUSSFILT);

% Create button image & Button
tempim=imnoise(zeros([16,16,3],'uint8'),'salt & pepper',0.2);
for ii=2:16, tempim(ii-1:ii,ii-1:ii,1)=255; tempim(ii-1:ii,ii-1:ii,2:3)=0 ;tempim([ii-1:ii],17-[ii-1:ii],1)=255; tempim([ii-1:ii],17-[ii-1:ii],2:3)=0; end
uipushtool(temp(1),'Cdata',tempim,...
    'Separator','off','TooltipString','Remove salt & pepper noise',...
    'HandleVisibility','on','Enable','on','ClickedCallback',@remove_SaltandPepper);

uipushtool(temp(1),'Tag','Correct rotation','Cdata',imread('correct_rotation.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','Cprrect for rotation',...
    'HandleVisibility','on','ClickedCallback',@estimate_rotation);
uipushtool(temp(1),'Tag','Remove Region','Cdata',imread('removeS.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','Draw a region to remove',...
    'HandleVisibility','on','ClickedCallback',@remove_region);
uipushtool(temp(1),'Tag','Undo last','Cdata',imread('undo.jpeg'),...
    'Separator','on','TooltipString','Undo last action',...
    'HandleVisibility','on','Enable','off','ClickedCallback',@Undo_remove);
uipushtool(temp(1),'Tag','Measure tick length','Cdata',imread('tick_length.png','BackgroundColor',[1 1 1]),...
    'Separator','on','TooltipString','Measure tick length',...
    'HandleVisibility','on','ClickedCallback',@meassure_pix_dist0);
% Image complement
polarity_ic=zeros([16,16,3]); for i=1:16, polarity_ic(1:i,i:16,:)=1;end
uipushtool(temp(1),'Tag','Measure tick length','Cdata',polarity_ic,...
    'Separator','on','TooltipString','Click to change image polarity',...
    'HandleVisibility','on','ClickedCallback',@change_I0_polarity);
clear polarity_ic;


% Time marks up or down
icon_m=zeros([16,16,3]); icon_m(8,:,:)=1; icon_m(4,6:10,:)=1; icon_m(13,6:10,1)=1;
H.timemarkpos=uitoggletool(temp(1),'Tag','Time marks relative position','Cdata',icon_m,...
    'Separator','on','TooltipString','Click to indicate that time mark offset occurs downward',...
    'HandleVisibility','on', 'State','off');
clear icon_m

H.tbar=findall(findall(H.f1,'Type','uitoolbar'));
H.tbar_UNDO=findobj(temp(1),'Tag','Undo last');


% uicontrols
% retrieve data, delete and reconstruct


temptimestr='yyyymmdd HH:MM:SS';
try, temptimestr=H.edit_t0.String; end
tempnumticks='';
try, tempnumticks=H.edit_num_of_ticks.String; end


delete(H.hp1)

% create again
H.hp1 = uipanel('Title','Reference time',...
    'BackgroundColor','white',...
    'Position',[.001 .78 .08 .22],'Parent',H.f1);

H.edit_t0=uicontrol('Style', 'pushbutton','Parent',H.hp1,'units','normalized',...
    'TooltipString','Date & Time of the 1st reference time mark (seismogram with time marks), or of the begining of the 1st trace (seismigram without time marks)',...
    'string', temptimestr,'Position',[0.02 0.72 0.96 0.19],...
    'BackgroundColor',[1 1 1],'Callback',@Get_DATE_TIME);
uicontrol('Style', 'Text','Parent',H.hp1,'units','normalized',...
    'String','# of time ticks',...
    'Position',[0.01 0.48 0.5 0.19],'BackgroundColor',[1 1 1]);
H.edit_num_of_ticks=uicontrol('Style', 'edit','Parent',H.hp1,'units','normalized',...
    'TooltipString','Number of time ticks between 1st and last (including 1st and last)',...
    'string',tempnumticks,'Position',[0.65 0.5 0.3 0.19],'BackgroundColor',[1 1 1]);
H.mark_1st=uicontrol('Style', 'pushbutton','Parent',H.hp1,'units','normalized',...
    'Tooltip','Mark the ending pixels of the 1st time marks',...
    'String', '1st mark','Position',[0.02 0.28 0.6 0.19],...
    'Callback',@(h,e) mark_1st_and_last(h,e,'FIRST',false));
H.edit_mark_1st=uicontrol('Style', 'pushbutton','Parent',H.hp1,'units','normalized',...
    'Tooltip','Edit the ending pixels of the 1st time marks',...
    'String', 'Edit','Position',[0.63 0.28 0.34 0.19],...
    'Callback',@(h,e) mark_1st_and_last(h,e,'FIRST',true),'Enable','on');
H.mark_last=uicontrol('Style', 'pushbutton','Parent',H.hp1,'units','normalized',...
    'Tooltip','Mark the last pixel of the last time marks',...
    'String', 'Last mark','Position', [0.02 0.05 0.6 0.19],...
    'Callback',@(h,e) mark_1st_and_last(h,e,'LAST',false));
H.edit_mark_last=uicontrol('Style', 'pushbutton','Parent',H.hp1,'units','normalized',...
    'Tooltip','Edit ending pixels of the last time marks',...
    'String', 'Edit','Position', [0.63 0.05 0.34 0.19],...
    'Callback',@(h,e) mark_1st_and_last(h,e,'LAST',true),'Enable','on');

delete(H.mark_start)
H.mark_start=uicontrol('Style', 'pushbutton','Parent',H.f1,'units','normalized',...
    'String', 'Start of traces','Position', [0.002 0.73 0.05 0.04],...
    'Callback',@(h,e) mark_start(h,e,0));

delete(H.pbedit_start)
H.pbedit_start=uicontrol('Style', 'pushbutton','Parent',H.f1,'units','normalized',...
    'String', 'Edit','Position', [0.052 0.73 0.028 0.04],...
    'Callback',@(h,e) mark_start(h,e,1),'Enable','on');

delete(H.mark_end)
H.mark_end=uicontrol('Style', 'pushbutton','Parent',H.f1,'units','normalized',...
    'String', 'End of traces','Position', [0.002 0.69 0.05 0.04],...
    'Callback',@(h,e) mark_end(h,e,0));

delete(H.pbedit_end)
H.pbedit_end=uicontrol('Style', 'pushbutton','Parent',H.f1,'units','normalized',...
    'String', 'Edit','Position', [0.052 0.69 0.028 0.04],...
    'Callback',@(h,e) mark_end(h,e,1),'Enable','on');

delete(H.togle_timebounds_visibility),
H.togle_timebounds_visibility=uicontrol('Style', 'checkbox','Parent',H.f1,'units','normalized',...
    'String', 'Time boundaries visible','Enable','on','BackgroundColor','w',...
    'Position', [0.002 0.65 0.08 0.03],'Callback',@togle_timebounds_visibility);


try, delete(H.togle_time_marks), end
% H.togle_time_marks=uicontrol('Style', 'checkbox','Parent',H.f1,'units','normalized',...
%     'String', 'Timing symbols visible','Enable','on','BackgroundColor','w',...
%     'Position', [0.002 0.62 0.08 0.03],'Callback',@togle_timesymbols_visibility);

%DT

temp={'60','1','720','25'};
try
    temp{1}=H.edit_DT.String; temp{2}=H.edit_DTtrace.String;
    temp{3}=H.edit_DP.String; temp{4}=H.edit_tick_xlength.String;
end

delete(H.edit_DT)
delete(H.edit_DTtrace)
delete(H.edit_DP)
delete(H.edit_tick_xlength)
H.edit_DT=uicontrol('Style', 'edit','Parent',H.f1,'units','normalized',...
    'TooltipString','Time difference between timemarks (s)','String',temp{1},...
    'Position',[0.002 0.59 0.038 0.035],'BackgroundColor',[1 1 1],'Enable','on');
H.edit_DTtrace=uicontrol('Style', 'edit','Parent',H.f1,'units','normalized',...
    'TooltipString','time difference between succeding traces (in hours)','String',temp{2},...
    'Position',[0.044 0.59 0.038 0.035],'BackgroundColor',[1 1 1],'Enable','on');
H.edit_DP=uicontrol('Style', 'edit','Parent',H.f1,'units','normalized',...
    'TooltipString','pixel dist between timemarks (px)','String', temp{3},...
    'Position',[0.002 0.55 0.038 0.035],'BackgroundColor',[1 1 1],'Enable','on');
H.edit_tick_xlength=uicontrol('Style', 'edit','Parent',H.f1,'units','normalized',...
    'TooltipString','Approximate time mark length (px)','String', temp{4},...
    'Position',[0.044 0.55 0.038 0.035],'BackgroundColor',[1 1 1],...
    'Callback',@Evaluate_ticklength_input);

delete(H.auto_num_of_traces)
H.auto_num_of_traces=uicontrol('Style', 'pushbutton','Parent',H.f1,'units','normalized',...
    'String', {'Identify traces', '& timemarks'},'Position', [0.002 0.505 0.08 0.04],...
    'Callback',@find_traces,'Enable','on');

delete(H.adjust_traces)
H.adjust_traces=uicontrol('Style', 'pushbutton','Parent',H.f1,'units','normalized',...
    'String', 'Adjust traces','Position', [0.002 0.465 0.08 0.04],'Callback',@adjust_traces);


delete(H.togle_traces_visibility)
H.togle_traces_visibility=uicontrol('Style', 'checkbox','Parent',H.f1,'units','normalized',...
    'String', 'Traces 0-line visible','Enable','on','Position', [0.002 0.435 0.08 0.03],...
    'BackgroundColor','w','Callback',@traces_visibility);
delete(H.togle_digital_traces_visibility)
H.togle_digital_traces_visibility=uicontrol('Style', 'checkbox','Parent',H.f1,'units','normalized',...
    'String', 'Digitized traces visible','Enable','on','Position', [0.002 0.412 0.08 0.03],...
    'BackgroundColor','w','Callback',@digital_traces_visibility);
try, delete(H.togle_digital_traces_STD_visibility), end;
H.togle_digital_traces_STD_visibility=uicontrol('Style', 'checkbox','Parent',H.f1,'units','normalized',...
    'String', 'Digitized traces std visible','Enable','on','Position', [0.002 0.39 0.08 0.03],...
    'BackgroundColor','w','Callback',@digital_traces_visibility);


delete(H.correct_classification)
H.correct_classification=uicontrol('Style', 'pushbutton','Parent',H.f1,'units','normalized',...
    'String', 'Edit classification','Position', [0.002 0.32 0.08 0.04],...
    'Callback',@correct_classification,'Enable','on');

delete(H.Create_Time)
H.Create_Time=uicontrol('Style', 'pushbutton','Parent',H.f1,'units','normalized',...
    'String', 'Calculate Timing','Position', [0.002 0.27 0.08 0.04],'Callback',@Create_Time,'Enable','on');

delete(H.text_luminance)
H.text_luminance=uicontrol('Style', 'text','Parent',H.f1,'units','normalized',...
    'String',{'Intensity';'threshold'},'Position', [0.002 0.2 0.04 0.04],'BackgroundColor',[1 1 1]);

temp='10';
try, temp=H.edit_luminance.String; end
delete(H.edit_luminance)
H.edit_luminance=uicontrol('Style', 'edit','Parent',H.f1,'units','normalized',...
    'TooltipString','Luminance thershold should be between 1 and 99',...
    'String',temp,'Position', [0.042 0.2 0.04 0.04],'BackgroundColor',[1 1 1]);

delete(H.text_offset)
H.text_offset=uicontrol('Style', 'text','Parent',H.f1,'units','normalized',...
    'String',{'Offset from trace';'to digitize'},'Position', [0.002 0.151 0.04 0.04],...
    'BackgroundColor',[1 1 1]);

temp='[-0.3 0.3]';
try, temp=H.edit_offset.String; end
delete(H.edit_offset)
H.edit_offset=uicontrol('Style', 'edit','Parent',H.f1,'units','normalized',...
    'TooltipString',...
    'Offset bellow and over the trace as a portion of the average trace distance, typical value: [0.3 0.3]',...
    'String',temp,'Position', [0.042 0.151 0.04 0.04],'BackgroundColor',[1 1 1]);
delete(H.digitize)
H.digitize=uicontrol('Style', 'pushbutton','Parent',H.f1,'units','normalized',...
    'String', 'Digitize','Position', [0.002 0.1 0.08 0.05],'Callback',@digitize_traces,'Enable','on');

delete(H.digitize_1)
H.digitize_1=uicontrol('Style', 'pushbutton','Parent',H.f1,'units','normalized',...
    'String', 'Correct trace','Position', [0.002 0.048 0.08 0.05],'Callback',@correct_trace);

delete(H.strMousePos)
H.strMousePos=uicontrol('Style', 'pushbutton','Parent',H.f1,'units','normalized',...
    'String', '','Tooltip','Push to reset','Position', [0.002 0.002 0.08 0.04],'Callback',set (H.f1, 'WindowButtonMotionFcn', @mouseMove));

set (H.f1, 'WindowButtonMotionFcn', @mouseMove); % Display continiously mouse location
disp('Completed.')
set(H.f1,'Visible','on')


drawnow
end



function Saveresults(hObject, eventdata)
global H HIM I0 HIMRGB BW ptrace ptraceSTD pt_traces pt_traceLABEL Time ftrend ftrend_tick S output_message  sumI ww pt_start_time pt_end_time p_tick_1st p_tick_last hresult_time_marks

%savefig(H.f1,['FIG_' get(H.textfilename,'String') '_.fig'])

%Gui_data = guidata(H.f1);

% Make everything visible
try
    set(H.togle_timebounds_visibility,'value',1); togle_timebounds_visibility;
end
try
    set(H.togle_time_marks,'value',1); togle_timesymbols_visibility;
end
try
    set(H.togle_traces_visibility,'value',1); traces_visibility;
end
try
    set(H.togle_digital_traces_visibility,'value',1); digital_traces_visibility;
end


DefaultName=['RESULTS_' get(H.textfilename,'String') '_.mat'];


[FileName,PathName] = uiputfile('.mat','Save Analysis and Results',DefaultName)

if isequal(FileName,0) || isequal(PathName,0)
    return
else
    
    
    % this is for making sure pt_traces are saved (DEBUGING)
    
    pt_tracesY=get(pt_traces,'Ydata');
    pt_tracesX=get(pt_traces,'Xdata');
    
    if any(ishandle(ptrace))
        itr=find(ishandle(ptrace));
        for iii=itr(:)' % to force itr be a row vector
            ptraceY{iii}=get(ptrace(iii),'Ydata');
            ptraceX{iii}=get(ptrace(iii),'Xdata');
        end
    else
        ptraceX={};
        ptraceY={};
    end
    
    save(fullfile(PathName,FileName),'H','HIM','HIMRGB','BW',...
        'I0', 'ptrace','ptraceSTD', 'pt_traces','pt_tracesX',...
        'pt_tracesY','ptraceX','ptraceY','pt_traceLABEL', 'Time',...
        'ftrend','ftrend_tick','S','output_message','sumI', 'ww', ...
        'pt_start_time', 'pt_end_time', 'p_tick_1st', 'p_tick_last',...
        'hresult_time_marks','-v7.3');
    
end





button = questdlg('Extract SAC files?','Save in SAC format','Yes','No','No');
if strcmp(button,'No')
    return
end


SEIS(length(ptrace))=struct('B',[],'DELTA',[],'x',[],'t',[],'E',[],'DATA1',[]);
for i=1:numel(ptrace)
    SEIS(i).DELTA=Time.DELTA;
    SEIS(i).x=get(ptrace(i),'XDATA');
    
    % This need update for efficiency.
    if str2double(get(H.edit_tick_xlength,'String'))>0
        SEIS(i).t=Time.trace(i).fx_t(SEIS(i).x);
    else
        SEIS(i).t=Time.trace(i).fx_t;
    end
    
    SEIS(i).FILENAME=[datestr(datestr(SEIS(i).t(1)),'yyyymmdd_HHMMSS') '_' datestr(datestr(SEIS(i).t(end)),'yyyymmdd_HHMMSS') '.SAC'];
    SEIS(i).B=etime(datevec(SEIS(i).t(1)),datevec(Time.RefDate));  % relative time from Reference Time
    SEIS(i).E=etime(datevec(SEIS(i).t(end)),datevec(Time.RefDate));  % relative time from Reference Time
    
    SEIS(i).y=get(ptrace(i),'YDATA');
    SEIS(i).ySTD=get(ptraceSTD(i),'YDATA');
    SEIS(i).trend=get(pt_traces(i),'YDATA');
    
    SEIS(i).reference_date=Time.RefDate;
    
    reltime=SEIS(i).B : SEIS(i).DELTA : SEIS(i).E;
    abstime=repmat(datevec(SEIS(i).reference_date),length(reltime),1);
    abstime(:,6)=abstime(:,6)+reltime(:);
    abstime=datenum(abstime);
    
    
    meanDATA1=mean(SEIS(i).DATA1(~isnan(SEIS(i).y)));
    SEIS(i).DATA1=SEIS(i).y-SEIS(i).trend;
    SEIS(i).DATA1=SEIS(i).DATA1-meanDATA1;
    SEIS(i).DATA1=interp1(SEIS(i).t,SEIS(i).DATA1,abstime);
    
    SEIS(i).DATA2=SEIS(i).ySTD-SEIS(i).y;
    SEIS(i).DATA2=interp1(SEIS(i).t,SEIS(i).DATA2,abstime);
    
    
    SEIS(i).NPTS=length(SEIS(i).DATA1);
    
    
    [y, m, d, HH, M, SEC]=datevec(Time.RefDate);
    SEIS(i).NZYEAR=y;
    SEIS(i).NZJDAY=datenum(y,m,d) - datenum(y, 1, 1) + 1;
    SEIS(i).NZHOUR=HH;
    SEIS(i).NZMIN=M;
    SEIS(i).NZSEC=floor(SEC);
    SEIS(i).NZMSEC=round(1000*(SEC - SEIS(i).NZSEC));
    
end

save(fullfile(PathName,FileName),'SEIS','-append')

saveassac(SEIS);

end







function Create_Time(hobject,eventdata)
global H Time

if str2double(get(H.edit_tick_xlength,'String'))>0
    Time=pixels2time;
else
    Time=pixels2time_no_timemarks;
end

end




function Time=pixels2time_no_timemarks()
global I0 H ftrend pt_traces hresult_time_marks
% if no time marks, then tick_length should be < 0 e.g., -999
% then Reference time SHOULD CORRESPOND to the beginging of the 1st trace.
% the p_tick_1st and last will not taken into consideration (the user can just ignore them)

Time=[];

% update user
%% needs improvement
output_message=get(H.output_mess,'String');
output_message{end+1}=['Timing seismogram... please wait'];
set(H.output_mess,'String',output_message,'Value',length(output_message)); drawnow
%%


try, delete(hresult_time_marks); end;
delete(findobj(H.ax1,'color','y'))
delete(findobj(H.ax1,'color','m'))
delete(findobj(H.ax1,'color',[1 1 0]))
delete(findobj('Type','rectangle'))

[rows,cols]=size(I0);

date0=datenum(get(H.edit_t0,'String'),'yyyymmdd HH:MM:SS');
%t0=datevec(date0);
pt_traces_Xdata=get(pt_traces,'Xdata');
%pt_traces_Ydata=get(pt_traces,'Ydata');

Dtrace=str2double(get(H.edit_DTtrace,'String')); % time between different traces in hours

% approximate num of pixels per trace.
%         <----l2---->|<--l1-->
%                 date0~~~~~~~~current_date
%          ~~~~~~~~~~~|~~~~~~~~
%          ~~~~~~~~~~~~~~~~~~~~


x1=pt_traces_Xdata{1}(1);
l1=abs(diff(pt_traces_Xdata{1}([1:end])));
[~,ix2]=min(pt_traces_Xdata{2}-x1);
l2=abs(diff(pt_traces_Xdata{2}([1 ix2]))) + ( pt_traces_Xdata{1}(end) - pt_traces_Xdata{2}(end) );

l1Time=l1*Dtrace/(l1+l2);
%l2Time=l2*Dtrace/(l1+l2);


tleft=datevec(addtodate(date0,round(1000*l1Time),'millisecond')); %the time at the left of the current trace

Time.RefDate=date0;
Time.DELTA=-inf;
for i=1:length(pt_traces)
    pxs=1:numel(pt_traces_Xdata{i});
    DELTAx=Dtrace/numel(pt_traces_Xdata{i}) * sqrt(1+diff(1+ftrend(pt_traces_Xdata{i}(1:end))).^2);
    Time.DELTA=max([DELTAx(:);Time.DELTA]);
    DELTAx=[DELTAx(1);DELTAx];
    
    tv=datevec(datenum(repmat([tleft(1:3) tleft(4)+(i-1)*Dtrace tleft(5:6)],length(pxs),1)));
    tv(:,6)=cumsum(DELTAx(pxs))-DELTAx(1);
    
    % Create time vector for each trace: Fx_t in this case is directly the
    % time vector.
    Time.trace(i).fx_t=datenum(tv);
    
    %% have to do
    %plot time marks in this case
    
    
end



% update user
output_message{end+1}=['Ready'];
set(H.output_mess,'String',output_message,'Value',length(output_message)); drawnow




end


function Time=pixels2time()
global I0 H S ftrend pt_traces pt_traceLABEL p_tick_1st p_tick_last hresult_time_marks

% update user
%% needs improvement
output_message=get(H.output_mess,'String');
output_message{end+1}=['Timing seismogram... please wait'];
set(H.output_mess,'String',output_message,'Value',length(output_message)); drawnow
%%

Time=[];

try, delete(hresult_time_marks); end;

delete(findobj(H.ax1,'color','y'))
delete(findobj(H.ax1,'color','m'))
delete(findobj(H.ax1,'color',[1 1 0]))
delete(findobj('Type','rectangle'))

[rows,cols]=size(I0);

date0=datenum(get(H.edit_t0,'String'),'yyyymmdd HH:MM:SS');
t0=datevec(date0);
pt_traces_Xdata=get(pt_traces,'Xdata');
pt_traces_Ydata=get(pt_traces,'Ydata');
x0=get(p_tick_1st,'Xdata');
x1=get(p_tick_last,'Xdata');
num_of_ticks=str2double(get(H.edit_num_of_ticks,'String'));

% Find the time kmark that corresponds to the reference time (1st time mark)
i_reference= find(~(isnan(x0)),1);


Dtrace=str2double(get(H.edit_DTtrace,'String')); % time between different traces
dt=str2double(get(H.edit_DT,'String'));

% theoretical delta correction as a function of x pixel coordinate
dp1=str2double(get(H.edit_DP,'String'));
tick_length=str2double(get(H.edit_tick_xlength,'String'));
itics=[S.ID]==1;

CALL=cell2mat({S(itics).BoundingBox}');

hold(H.ax1,'on')



a=nan(length(pt_traces),1);
for i=1:length(pt_traces) % optimize ftrend
    if ~isnan(x0(i)) &&  ~isnan(x1(i))
        a(i) = fminbnd(@(x)CostDelta(x,dt,dp1,ftrend,cols,x0(i):x1(i),num_of_ticks) ,0.9,1.1);
    end
end
a=median(a(~isnan(a)));



if strcmpi(get(H.timemarkpos,'state'),'off')
    npt_traces_togo=length(pt_traces);
    ylimits=[-100; 10];
else
    npt_traces_togo=length(pt_traces)-1;
    ylimits=[100; -10];
end

DELTA=-inf;
for i=1:npt_traces_togo
    
    if strcmpi(get(H.timemarkpos,'state'),'off')
        ic= CALL(:,2)+CALL(:,4)/2<=pt_traces_Ydata{i}(1)+ftrend(CALL(:,1)) &...
            CALL(:,1)>=pt_traces_Xdata{i}(1) & CALL(:,1)+CALL(:,3)<=pt_traces_Xdata{i}(end);
    else
        ic= CALL(:,2)+CALL(:,4)/2<=pt_traces_Ydata{i+1}(1)+ftrend(CALL(:,1)) &...
            CALL(:,1)>=pt_traces_Xdata{i+1}(1) & CALL(:,1)+CALL(:,3)<=pt_traces_Xdata{i+1}(end);
    end
    
    if ~isnan(x0(i)) &&  ~isnan(x1(i))
        
        ipxs=find(pt_traces_Xdata{i}==x0(i)):find(pt_traces_Xdata{i}==x1(i));
        pxs=x0(i):x1(i);
        
        DELTAx=dt/dp1 * a*sqrt(1+diff(1+ftrend(1:cols)).^2); DELTA=max([DELTA; DELTAx(:)]);
        tempY=pt_traces_Ydata{i}(ipxs);
        
        tv=datevec(datenum(repmat([t0(1:3) t0(4)+(i-i_reference)*Dtrace t0(5:6)],length(pxs),1)));
        
        tv(:,6)=cumsum(DELTAx(pxs))-DELTAx(ipxs(1));
        tnum=datenum(tv);
        tv=datevec(tnum);
        iMM=[true; abs(diff(tv(:,5)))>eps]'; % find round minutes
        if (tv(end,6)<eps)
            iMM(end)=true;
        end
        
        theor_ticks=pxs(iMM);
        
        tempX=repmat(theor_ticks,2,1);
        tempY=repmat(tempY(iMM),2,1);
        tempY=tempY+repmat(ylimits,1,size(tempY,2));
        plot(H.ax1,tempX,tempY,'m--','LineWidth',1);
        
        % find tick marks of current trace
        %ic= CALL(:,2)<=[pt_traces_Ydata{i}(1)+ftrend(CALL(:,1))];
        C=CALL(ic,:);
        CALL(ic,:)=[];
        
        
        %plot(H.ax1,1:cols,[pt_traces_Ydata{i}(1)+ftrend(1:cols)],'y:')
        
        % combine very close tickmarks
        [~,isortx]=sort(C(:,1));
        C=C(isortx,:);
        iclose=find([C(2:end,1) - C(1:end-1,1)] < tick_length);
        if ~isempty(iclose)
            C(iclose,3)=max(C(iclose,1)+C(iclose,3),C(iclose+1,1)+C(iclose+1,3))-C(iclose,1);
            C(iclose,4)=max(C(iclose,2)+C(iclose,4),C(iclose+1,2)+C(iclose+1,4))-min(C(iclose,2),C(iclose+1,2));
            C(iclose+1,:)=[];
        end
        actual_ticks=C(:,1)+C(:,3);
        
        for k=1:size(C,1)
            rectangle('Position',C(k,:),'EdgeColor','y','Parent',H.ax1);
        end
        
        ty=tnum(iMM);
        [Dist,iDist] = pdist2(theor_ticks',actual_ticks,'euclidean','Smallest',1);
        ty=ty(iDist);
        
        % delete distant ticks
        ito_delete=abs(Dist)>dp1/3;
        iDist(ito_delete)=[];
        ty(ito_delete)=[];
        actual_ticks(ito_delete)=[];
        
        % delete doubles
        ito_delete=false(size(iDist));
        for j=1:length(iDist)-1
            if iDist(j)==iDist(j+1);
                ito_delete(j:j+1)=true;
            end
        end
        ty(ito_delete)=[];
        actual_ticks(ito_delete)=[];
        iDist(ito_delete)=[];
        
        %      if numel(unique(iDist))~=numel(iDist);
        %         error('iDist doubles ')
        %     end
        
        % Create function(x)-->time for each trace
        Time.trace(i).fx_t=fit(actual_ticks,ty,'linearinterp');
        
        % plot
        tv=datevec(Time.trace(i).fx_t(pt_traces_Xdata{i}));
        iMM=[abs(diff(tv(:,5)))>eps; false]';
        if (tv(end,6)<0.001)
            iMM(end)=true;
        end
        
        
        tempX=repmat(pt_traces_Xdata{i}(iMM),2,1);
        tempY=repmat(pt_traces_Ydata{i}(iMM),2,1);
        tempY=tempY+repmat(ylimits,1,size(tempY,2));
        plot(H.ax1,tempX,tempY,'-o','Color',[1 1 0]);
        
    else
        % find and remove tick marks of current trace
        CALL(ic,:)=[];
        
        Time.trace(i).fx_t=[];
    end
    
    % put an empty vector for the last trace if time-marks are downwards
    if npt_traces_togo<length(pt_traces)
        Time.trace(length(pt_traces)).fx_t=[];
    end
    
end
hold(H.ax1,'off')

Time.DELTA=DELTA;
Time.RefDate=date0;

% If trace is too short to be included, calculate time from closest ok trace
itodo=find(cell2mat(cellfun(@(x) isempty(x),{Time.trace(:).fx_t},'UniformOutput',false)));
for i=itodo
    
    % create vector (i-1,i+1,i-2,i+2, etc)
    totest1=[i-1:-1:1]; n1=numel(totest1);
    totest2=[i+1:length(pt_traces)]; n2=numel(totest2);
    totest= zeros(1,n1+n2); %sort(abs (i - [1:i-1, i+1:length(pt_traces)]));
    if n1<n2
        totest(1:2:2*n1)=totest1;
        totest(2:2:2*n1)=totest2(1:n1);
        totest(2*n1+1:end)=totest2(n1+1:end);
    else
        totest(1:2:2*n2)=totest2;
        totest(2:2:2*n2)=totest1(1:n2);
        totest(2*n2+1:end)=totest1(n2+1:end);
    end
    
    
    for j=totest;
        if ~isempty(Time.trace(j).fx_t)
            ty=datevec(Time.trace(j).fx_t(pt_traces_Xdata{i}));
            ty(:,5)=ty(:,5)+(i-j)*60*Dtrace;
            
            
            Time.trace(i).fx_t=fit(pt_traces_Xdata{i}(:),datenum(ty),'cubicinterp');
            break
        end
    end
end


% get handles for time symbols
hresult_time_marks=findobj(H.ax1,'color','y');
set(hresult_time_marks,'LineWidth',2)
hresult_time_marks=[hresult_time_marks;...
    findobj(H.ax1,'color','m');...
    findobj(H.ax1,'Edgecolor','y')];

set(H.togle_time_marks,'Enable','on');

% update user
output_message{end+1}=['Ready'];
set(H.output_mess,'String',output_message,'Value',length(output_message)); drawnow

%disp('xoxoxo')
end


function cost=CostDelta(x,dt,dp1,ftrend,cols,pxs,num_of_ticks)

DELTAx=dt/dp1 *x*sqrt(1+diff(1+ftrend(1:cols)).^2);
tv=repmat([0 0 0 0 0 0],numel(pxs),1);
tv(:,6)=cumsum(DELTAx(pxs))-DELTAx(pxs(1));
tv=datevec(datenum(tv));
iMM=[abs(diff(tv(:,5)))>eps]; % find round minutes
theor_ticks=pxs(iMM);
cost=abs( num_of_ticks-length(theor_ticks) -1)*2*dp1 +  abs(theor_ticks(end)-pxs(end));

end






function saveassac(SEIS)
global H
% save digitized traces in sac format

%    FILENAME   - File name of SAC data file
%    DELTA      - Data sampling interval
%    DEPMIN     - Minimum value of dependent variable
%    DEPMAX     - Maximum value of dependent variable
%    SCALE      - Multiplying factor for dependent variable
%    ODELTA     - Observed increment if different from nominal
%    B          - Beginning value of independent variable
%    E          - Ending value of independent variable
%    O          - Event origin time
%    A          - First arrival time
%    INTERNAL1  - First internal variable
%    T0         - First user-defined time picks or markers
%    T1         - Second user-defined time picks or markers
%    T2         - Third user-defined time picks or markers
%    T3         - Fourth user-defined time picks or markers
%    T4         - Fifth user-defined time picks or markers
%    T5         - Sixth user-defined time picks or markers
%    T6         - Seventh user-defined time picks or markers
%    T7         - Eighth user-defined time picks or markers
%    T8         - Ninth user-defined time picks or markers
%    T9         - Tenth user-defined time picks or markers
%    F          - Final or end of event time
%    RESP0      - First instrument response parameter
%    RESP1      - Second instrument response parameter
%    RESP2      - Third instrument response parameter
%    RESP3      - Fourth instrument response parameter
%    RESP4      - Fifth instrument response parameter
%    RESP5      - Sixth instrument response parameter
%    RESP6      - Seventh instrument response parameter
%    RESP7      - Eighth instrument response parameter
%    RESP8      - Ninth instrument response parameter
%    RESP9      - Tenth instrument response parameter
%    STLA       - Station latitude
%    STLO       - Station longitude
%    STEL       - Station elevation
%    STDP       - Station depth
%    EVLA       - Event latitude
%    EVLO       - Event longitude
%    EVEL       - Event elevation
%    EVDP       - Event depth
%    MAG        - Event magnitude
%    USER0      - First user-defined variable
%    USER1      - Second user-defined variable
%    USER2      - Third user-defined variable
%    USER3      - Fourth user-defined variable
%    USER4      - Fifth user-defined variable
%    USER5      - Sixth user-defined variable
%    USER6      - Seventh user-defined variable
%    USER7      - Eighth user-defined variable
%    USER8      - Ninth user-defined variable
%    USER9      - Tenth user-defined variable
%    DIST       - Station-to-event distance (km)
%    AZ         - Event-to-station azimuth (degree)
%    BAZ        - Station-to-event azimuth (degree)
%    GCARC      - Station-to-event great-circle arc length (degree)
%    INTERNAL2  - Second internal variable
%    INTERNAL3  - Third internal variable
%    DEPMEN     - Mean value of dependent variable
%    CMPAZ      - Component azimuth
%    CMPINC     - Component incident angle
%    XMINIMUM   - Minimum value of X (spectral file only)
%    XMAXIMUM   - Maximum value of X (spectral file only)
%    YMINIMUM   - Minimum value of Y (spectral file only)
%    YMAXIMUM   - Maximum value of Y (spectral file only)
%    UNUSED1    - First unused variable
%    UNUSED2    - Second unused variable
%    UNUSED3    - Third unused variable
%    UNUSED4    - Fourth unused variable
%    UNUSED5    - Fifth unused variable
%    UNUSED6    - Sixth unused variable
%    UNUSED7    - Seventh unused variable
%    NZYEAR     - GMT year corresponding to reference time
%    NZJDAY     - GMT julian day corresponding to reference time
%    NZHOUR     - GMT hour corresponding to reference time
%    NZMIN      - GMT minute corresponding to reference time
%    NZSEC      - GMT second corresponding to reference time
%    NZMSEC     - GMT milisecond corresponding to reference time
%    NVHDR      - Header version
%    NORID      - Origin ID
%    NEVID      - Event ID
%    NPTS       - Number of data points
%    INTERNAL4  - Fourth internal variable
%    NWFID      - Waveform ID
%    NXSIZE     - Spectral length (spectral file only)
%    NYSIZE     - Spectral width (spectral file only)
%    UNUSED8    - Eighth unused variable
%    IFTYPE     - Type of file
%    IDEP       - Type of dependent variable
%    IZTYPE     - Reference-time equivalence
%    UNUSED9    - Ninth unused variable
%    IINST      - Type of recording instrument
%    ISTREG     - Station geographic region
%    IEVREG     - Event geographic region
%    IEVTYP     - Type of event
%    IQUAL      - Quality of data
%    ISYNTH     - Synthetic data flag
%    IMAGTYP    - Magnitude type
%    IMAGSRC    - Magnitude source
%    UNUSED10   - Tenth unused variable
%    UNUSED11   - Eleventh unused variable
%    UNUSED12   - Twelveth unused variable
%    UNUSED13   - Thirteenth unused variable
%    UNUSED14   - Fourteenth unused variable
%    UNUSED15   - Fifteenth unused variable
%    UNUSED16   - Sixteenth unused variable
%    UNUSED17   - Seventeenth unused variable
%    LEVEN      - True if data is evenly spaced
%    LPSPOL     - True if station polarity follows left-hand rule
%    LOVROK     - True if it is ok to overwrite this file on disk
%    LCALDA     - True if DIST, AZ, BAZ and GCARC are to be calculated from
%                 station and event coordinates
%    UNUSED18   - Eighteenth unused variable
%    KSTNM      - Station name
%    KEVNM      - Event name
%    KHOLE      - Hole ID for nuclear test
%    KO         - Event origin time ID
%    KA         - First arrival time ID
%    KT0        - First user-defined time pick ID
%    KT1        - Second user-defined time pick ID
%    KT2        - Third user-defined time pick ID
%    KT3        - Fourth user-defined time pick ID
%    KT4        - Fifth user-defined time pick ID
%    KT5        - Sixth user-defined time pick ID
%    KT6        - Seventh user-defined time pick ID
%    KT7        - Eighth user-defined time pick ID
%    KT8        - Ninth user-defined time pick ID
%    KT9        - Tenth user-defined time pick ID
%    KF         - Final or end event time ID
%    KUSER0     - First user-defined text string
%    KUSER1     - Second user-defined text string
%    KUSER2     - Third user-defined text string
%    KCMPNM     - Component name
%    KNETWK     - Network name
%    KDATRD     - Date data were read onto computer
%    KINST      - Generic name of recording instrument
%    DATA1      - First data block

field_names={'FILENAME','DELTA','DEPMIN','DEPMAX','SCALE','ODELTA','B','E','O','A','INTERNAL1',...
    'T0','T1','T2','T3','T4','T5','T6','T7','T8','T9','F','RESP0','RESP1','RESP2','RESP3',...
    'RESP4','RESP5','RESP6','RESP7','RESP8','RESP9','STLA','STLO','STEL','STDP','EVLA',...
    'EVLO','EVEL','EVDP','MAG','USER0','USER1','USER2','USER3','USER4','USER5','USER6',...
    'USER7','USER8','USER9','DIST','AZ','BAZ','GCARC','INTERNAL2','INTERNAL3','DEPMEN',...
    'CMPAZ','CMPINC','XMINIMUM','XMAXIMUM','YMINIMUM','YMAXIMUM','UNUSED1','UNUSED2','UNUSED3',...
    'UNUSED4','UNUSED5','UNUSED6','UNUSED7','NZYEAR','NZJDAY','NZHOUR','NZMIN','NZSEC','NZMSEC',...
    'NVHDR','NORID','NEVID','NPTS','INTERNAL4','NWFID','NXSIZE','NYSIZE','UNUSED8','IFTYPE','IDEP',...
    'IZTYPE','UNUSED9','IINST','ISTREG','IEVREG','IEVTYP','IQUAL','ISYNTH','IMAGTYP','IMAGSRC',...
    'UNUSED10','UNUSED11','UNUSED12','UNUSED13','UNUSED14','UNUSED15','UNUSED16','UNUSED17',...
    'LEVEN','LPSPOL','LOVROK','LCALDA','UNUSED18','KSTNM','KEVNM','KHOLE','KO','KA','KT0','KT1',...
    'KT2','KT3','KT4','KT5','KT6','KT7','KT8','KT9','KF','KUSER0','KUSER1','KUSER2','KCMPNM',...
    'KNETWK','KDATRD','KINST'};
% DATA1

% Initialize
N = length(SEIS);
clear tS;
tS(N)=struct();
nfields=length(field_names);
for it=1:86
    [tS.(field_names{it})]=deal(nan);
end
% 87 up to 89
[tS.IFTYPE]=deal('ITIME');
[tS.IDEP]=deal('IUNKN'); % This should be changed in future version to reflect the units.
[tS.IZTYPE]=deal(''); % This should be changed in future version to reflect the units.
for it=90:93
    [tS.(field_names{it})]=deal(nan);
end
for it=94:98    % IEVTYP up to IMAGSRC = ''
    [tS.(field_names{it})]=deal('');
end
for it=99:111
    [tS.(field_names{it})]=deal(nan);
end
for it=112:nfields
    [tS.(field_names{it})]=deal('');
end


[tS.LEVEN]=deal(1); % Even sampling distance

[tS.FILENAME]=deal(SEIS.FILENAME);
[tS.DELTA]=deal(SEIS.DELTA);
[tS.B]=deal(SEIS.B);
[tS.E]=deal(SEIS.E);
[tS.NPTS]=deal(SEIS.NPTS);
[tS.NZYEAR]=deal(SEIS.NZYEAR);
[tS.NZJDAY]=deal( SEIS.NZJDAY);
[tS.NZHOUR]= deal(SEIS.NZHOUR);
[tS.NZMIN]= deal(SEIS.NZMIN);
[tS.NZSEC]= deal(SEIS.NZSEC);
[tS.NZMSEC]= deal(SEIS.NZMSEC);

% HRV defaults
[tS.KSTNM]=deal('HRV');
[tS.STLA]=deal(42.506);
[tS.STLO]=deal(-71.558);
[tS.STEL]=deal(200);


Fig_table = figure('Units','Normalized','Position',[0.2 0.1 0.4 0.7],...
    'color','w','WindowStyle','Normal','NumberTitle','Off','Name','Save in SAC format');
columnname =   num2str([1:length(SEIS)]');
columneditable =  true(size(field_names));
columneditable(end)=false;
htabl = uitable('Units','normalized','Position',...
    [0.01 0.15 0.98 0.85], 'Data',struct2cell( tS(:) ),...
    'ColumnName', columnname,...
    'ColumnEditable', columneditable,...
    'RowName',field_names,'Parent',Fig_table);



uicontrol('Style', 'Text','Parent',Fig_table,'units','normalized',...
    'String', 'Network','Tooltip','Enter network name (KNETWK field)','BackgroundColor',[1 1 1],...
    'Position', [0.01 0.1 0.095 0.03]);
uicontrol('Style', 'Text','Parent',Fig_table,'units','normalized',...
    'String', 'Station','Tooltip','Enter station name (KSTNM field)','BackgroundColor',[1 1 1],...
    'Position', [0.11 0.1 0.095 0.03]);
uicontrol('Style', 'Text','Parent',Fig_table,'units','normalized',...
    'String', 'Component','Tooltip','Enter component name (KCMPNM field)','BackgroundColor',[1 1 1],...
    'Position', [0.21 0.1 0.095 0.03]);
uicontrol('Style', 'Text','Parent',Fig_table,'units','normalized',...
    'String', 'Hole ID','Tooltip','Enter Hole ID (KHOLE field)','BackgroundColor',[1 1 1],...
    'Position', [0.31 0.1 0.095 0.03]);
uicontrol('Style', 'Text','Parent',Fig_table,'units','normalized',...
    'String', 'Instrument','Tooltip','Enter generic name of recording instrument (KINST field)','BackgroundColor',[1 1 1],...
    'Position', [0.41 0.1 0.095 0.03]);
uicontrol('Style', 'Text','Parent',Fig_table,'units','normalized',...
    'String', 'latitude','Tooltip','Station latitude (STLA field)','BackgroundColor',[1 1 1],...
    'Position', [0.51 0.1 0.095 0.03]);
uicontrol('Style', 'Text','Parent',Fig_table,'units','normalized',...
    'String', 'longitude','Tooltip','Station longitude  (STLO field)','BackgroundColor',[1 1 1],...
    'Position', [0.61 0.1 0.095 0.03]);
uicontrol('Style', 'Text','Parent',Fig_table,'units','normalized',...
    'String', 'Elevation','Tooltip','Station elevation (STEL field)','BackgroundColor',[1 1 1],...
    'Position', [0.71 0.1 0.095 0.03]);
uicontrol('Style', 'Text','Parent',Fig_table,'units','normalized',...
    'String', 'Depth','Tooltip','Station depth','BackgroundColor',[1 1 1],...
    'Position', [0.81 0.1 0.095 0.03]);

ht_eKNETWK=uicontrol('Style', 'Edit','Parent',Fig_table,'units','normalized','tag','KNETWK',...
    'String', '','Tooltip','Enter network name (KNETWK field)','BackgroundColor',[1 1 1],...
    'Position', [0.01 0.07 0.095 0.03],'Callback',@update_table);
ht_eKSTNM=uicontrol('Style', 'Edit','Parent',Fig_table,'units','normalized','tag','KSTNM',...
    'String', 'HRV','Tooltip','Enter station name (KSTNM field)','BackgroundColor',[1 1 1],...
    'Position', [0.11 0.07 0.095 0.03],'Callback',@update_table);
ht_eKCMPNM=uicontrol('Style', 'Edit','Parent',Fig_table,'units','normalized','tag','KCMPNM',...
    'String', '','Tooltip','Enter component name (KCMPNM field)','BackgroundColor',[1 1 1],...
    'Position', [0.21 0.07 0.095 0.03],'Callback',@update_table);
ht_eKHOLE=uicontrol('Style', 'Edit','Parent',Fig_table,'units','normalized','tag','KHOLE',...
    'String', '','Tooltip','Enter Hole ID (KHOLE field)','BackgroundColor',[1 1 1],...
    'Position', [0.31 0.07 0.095 0.03],'Callback',@update_table);
ht_eKINST=uicontrol('Style', 'Edit','Parent',Fig_table,'units','normalized','tag','KINST',...
    'String', '','Tooltip','Enter generic name of recording instrument (KINST field)',...
    'BackgroundColor',[1 1 1],'Position', [0.41 0.07 0.095 0.03],'Callback',@update_table);
ht_eSTLA=uicontrol('Style', 'Edit','Parent',Fig_table,'units','normalized','tag','STLA',...
    'String', '42.506','Tooltip','Station latitude (STLA field)',...
    'BackgroundColor',[1 1 1],'Position', [0.51 0.07 0.095 0.03],'Callback',@update_table);
ht_eSTLO=uicontrol('Style', 'Edit','Parent',Fig_table,'units','normalized','tag','STLO',...
    'String', '-71.558','Tooltip','Station longitude  (STLO field)',...
    'BackgroundColor',[1 1 1],'Position', [0.61 0.07 0.095 0.03],'Callback',@update_table);
ht_eSTEL=uicontrol('Style', 'Edit','Parent',Fig_table,'units','normalized','tag','STEL',...
    'String', '200','Tooltip','Station elevation (STEL field)',...
    'BackgroundColor',[1 1 1],'Position', [0.71 0.07 0.095 0.03],'Callback',@update_table);
ht_eSTDP=uicontrol('Style', 'Edit','Parent',Fig_table,'units','normalized','tag','STDP',...
    'String', '','Tooltip','Station depth',...
    'BackgroundColor',[1 1 1],'Position', [0.81 0.07 0.095 0.03],'Callback',@update_table);


ht_eCMPAZ=uicontrol('Style', 'Edit','Parent',Fig_table,'units','normalized','tag','CMPAZ',...
    'String', '','Tooltip','Enter component azimuth (CMPAZ field)','BackgroundColor',[1 1 1],...
    'Position', [0.21 0.036 0.095 0.025],'Callback',@update_table);
ht_eCMPINC=uicontrol('Style', 'Edit','Parent',Fig_table,'units','normalized','tag','CMPINC',...
    'String', '','Tooltip','Enter component incidence angle (CMPINC field)','BackgroundColor',[1 1 1],...
    'Position', [0.21 0.01 0.095 0.025],'Callback',@update_table);



hp_saveassac=uicontrol('Style', 'pushbutton','Parent',Fig_table,'units','normalized',...
    'String', 'Generate Sac files','Position', [0.82 0.01 0.17 0.04],'Callback',@saveassac);




    function update_table(hObject, eventdata)
        data = get(htabl,'Data');
        data(~cellfun('isempty',strfind(field_names, get(hObject,'tag'))),:) = {get(hObject,'String')};
        set(htabl,'Data',data);
    end


    function saveassac(hObject, eventdata)
        
        folder_name = uigetdir(get(H.textfilename,'Userdata'),'Select folder to generate SAC files');
        if (folder_name==0), return, end
        
        hbar=waitbar(0,'please wait...','Name','Generating SAC files');
        
        clear SAC;
        data = get(htabl,'Data');
        SAC = cell2struct(data, field_names, 1);
        nS=length(SAC);
        total_wait=nS+30;
        for i=1:nS
            waitbar(i/total_wait,hbar,'Creating SAC structure, please wait...')
            SAC(i).DATA1=SEIS(i).DATA1;
            if isfield(SEIS,DATA2)
                SAC(i).DATA2=SEIS(i).DATA2;
            end
            
        end
        
        
        oldFolder = cd(folder_name);
        waitbar(0.8,hbar,'Writing SAC files, please wait...')
        writesac(SAC);
        waitbar(0.99,hbar,'Completed.')
        cd(oldFolder)
        delete(hbar);
        close(Fig_table);
    end


end


