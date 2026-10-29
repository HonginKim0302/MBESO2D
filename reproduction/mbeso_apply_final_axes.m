function mbeso_apply_final_axes(f)
%MBESO_APPLY_FINAL_AXES End each visible y-axis at a labeled round tick.
% Experimental arrays, font sizes and material identities are unchanged.
aa=findall(f,'Type','axes');
for j=1:numel(aa)
    a=aa(j);
    if strcmp(a.Visible,'off'),continue;end
    switch a.Tag
        case 'panel_a'
            if isempty(findobj(a,'Tag','C_Nmm')),continue;end
            a.YAxis(1).Limits=[0 6];a.YAxis(1).TickValues=0:6;
            a.YAxis(2).Limits=[0 800];a.YAxis(2).TickValues=0:200:800;
        case 'panel_b'
            if isempty(findobj(a,'Tag','trace_raw_974_MPa')),continue;end
            a.YLim=[-2 10];a.YTick=-2:2:10;
        case 'panel_c'
            if isempty(findobj(a,'Tag','eta_raw_974')),continue;end
            a.YLim=[0 .5];a.YTick=0:.1:.5;
        case 'Figure3_b'
            a.YLim=[-40 40];a.YTick=-40:20:40;
        case 'Figure3_c'
            a.YLim=[0 8000];a.YTick=0:2000:8000;
        case 'Figure3_e'
            a.YLim=[0 10];a.YTick=0:2:10;
        case 'Figure4_c'
            a.YLim=[0 120];a.YTick=0:30:120;
        case 'Figure4_d'
            a.YLim=[0 3];a.YTick=0:.5:3;
    end
    for k=1:numel(a.YAxis),a.YAxis(k).Exponent=0;end
    % Keep combined overviews intact; equalize the three standalone panels.
    if numel(aa)==1 && ismember(a.Tag,{'Figure3_b','Figure3_c','Figure3_e'})
        root=fileparts(mfilename('fullpath'));
        layout=jsondecode(fileread(fullfile(root,'fig10_panel_layout.json')));
        box=layout.axes_cm(:)';canvas=layout.canvas_cm(:)';
        fu=f.Units;f.Units='centimeters';scale=f.Position(3:4)./canvas;f.Units=fu;
        au=a.Units;a.Units='centimeters';
        a.Position=box.*[scale scale];
        a.Units=au;
    end
end
set(findall(f,'Type','legend'),'Box','on','EdgeColor',[0 0 0]);
setappdata(f,'MBESO_FinalAxesStyleVersion','2026-10-19-round-axes-v1');
end
