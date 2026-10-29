function checks=verify_manuscript_outputs
%VERIFY_MANUSCRIPT_OUTPUTS Compare exported native plots with the experiment arrays.
root=fileparts(mfilename('fullpath'));rows={};
M=readtable(fullfile(root,'generated_artifacts.csv'),'TextType','string');
G=readtable(fullfile(root,'manuscript_panel_geometry.csv'),'TextType','string');
z=load(fullfile(root,'figure_06/data/plot_inputs.mat'));B=z.P;
z=load(fullfile(root,'figure_08/data/plot_inputs.mat'));H=z.P;
z=load(fullfile(root,'figure_09/data/plot_inputs_214.mat'));D=z.P;
F=mbeso_figure9_baseline_data(fullfile(root,'figure_09','data'));
check('numeric_panel_count',nnz(M.numeric_panel),11,0);
check('new_Fig09_panels_present',nnz(M.numeric_panel & M.manuscript_figure==9 & ismember(M.panel,["e","f_1","f_2"])),3,0);
oldPath=path;guard=onCleanup(@()path(oldPath)); %#ok<NASGU>
addpath(fullfile(root,'figure_08'),'-begin');local=mbeso_figure1_update_data(H);
for j=find(M.numeric_panel)'
    id=sprintf('Fig%02d_%s',M.manuscript_figure(j),M.panel(j));
    f=openfig(fullfile(root,M.fig(j)),'new','invisible');
    clean=onCleanup(@()close(f));
    g=G(G.manuscript_figure==M.manuscript_figure(j)&G.panel==M.panel(j),:);
    f.PaperUnits='centimeters';
    check([id '_page_mm'],10*f.PaperSize,[g.width_mm g.height_mm],1e-8);
    fonts=findall(f,'-property','FontName');
    check([id '_Times_New_Roman'],all(arrayfun(@(h)strcmp(h.FontName,'Times New Roman'),fonts)),true,0);
    for lg=findall(f,'Type','legend')'
        check([id '_legend_black_frame'],lg.EdgeColor,[0 0 0],0);
        check([id '_legend_box'],strcmp(lg.Box,'on'),true,0);
        check([id '_legend_black_text'],lg.TextColor,[0 0 0],0);
    end
    aa=findall(f,'Type','axes');
    for a=aa'
        check([id '_frame_and_grid'],strcmp(a.Box,'on')&&strcmp(a.XGrid,'on')&&strcmp(a.YGrid,'on'),true,0);
        check([id '_no_panel_title'],isempty(a.Title.String),true,0);
        for y=a.YAxis'
            check([id '_upper_axis_labeled'],y.Limits(2),y.TickValues(end),0);
        end
    end
    switch id
        case 'Fig06_c'
            series('deck_force',B.external_MN);series('selfweight_force',B.selfweight_MN);
            series('support_reaction',B.reaction_MN);
        case 'Fig06_d'
            series('deck_energy',B.energy_components_MNm(:,1));
            series('cross_energy',B.energy_components_MNm(:,2));
            series('selfweight_energy',B.energy_components_MNm(:,3));
            series('total_compliance',B.C_production_MNm);
        case 'Fig08_a'
            for tag={'Vk','nk','V1','C_Nmm'},series(tag{1},H.response.(tag{1}),(0:214)');end
            h=findobj(f,'Tag','V1');check([id '_tensile_blue'],h.Color,[0 0 1],0);
            check([id '_initial_ten_band'],numel(findall(f,'Tag','initial_ten_updates')),1,0);
        case 'Fig08_b'
            for tag={'trace_raw_974_MPa','trace_filtered_974_MPa'},series(tag{1},local.(tag{1}),(1:10)');end
        case 'Fig08_c'
            for tag={'eta_raw_974','eta_spatial_974','eta_temporal_974','eta_temporal_5829','selection_cutoff'}
                series(tag{1},local.(tag{1}),(1:10)');
            end
        case 'Fig09_b'
            for k=1:5,series(['Figure3_b_' D.run_ids{k}],D.C_change_same_state_percent(:,k),(0:214)');end
            check([id '_ylim'],aa.YLim,[-40 40],0);
        case 'Fig09_c'
            for k=1:2,series(sprintf('Figure3_c_series_%d',k),D.counts_updates_2_214(:,k));end
            check([id '_ylim'],aa.YLim,[0 8000],0);
        case 'Fig09_e'
            series('actual_solid',100*F.solid_fraction(2:215),(1:214)');
            series('b_tensile',100*F.V1(2:215),(1:214)');
            series('b_compressive',100*F.V2(2:215),(1:214)');
            h=findobj(f,'Tag','actual_solid');check([id '_solid_gray'],h.Color,[.48 .48 .48],0);
            h=findobj(f,'Tag','b_tensile');check([id '_tensile_blue'],h.Color,[0 0 1],0);
            h=findobj(f,'Tag','b_compressive');check([id '_compressive_red'],h.Color,[1 0 0],0);
            lg=findobj(f,'Type','legend');
            check([id '_material_legend'],isequal(plainSymbols(string(lg.String(:))),["Actual solid";"V_1 (tensile)";"V_2 (compressive)"]),true,0);
            check([id '_ylim'],aa.YLim,[0 100],0);
        case {'Fig09_f_1','Fig09_f_2'}
            if strcmp(id,'Fig09_f_1'),k=2:214;else,k=195:214;end
            series('material_transitions',F.N_TC(k),k');
            series('solid_void_transitions',F.N_SV(k),k');
            h=findobj(f,'Tag','material_transitions');check([id '_material_brown'],h.Color,[.72 .47 .10],0);
            h=findobj(f,'Tag','solid_void_transitions');check([id '_solid_void_gray'],h.Color,[.48 .48 .48],0);
            lg=findobj(f,'Type','legend');
            check([id '_legend_no_title'],isempty(lg.Title.String),true,0);
            if strcmp(id,'Fig09_f_1')
                check([id '_full_no_markers'],strcmp(h.Marker,'none'),true,0);
                check([id '_ylim'],aa.YLim,[0 1200],0);
                check([id '_tick195'],any(aa.XTick==195),true,0);
                check([id '_round_axis_end250'],aa.XTick(end),250,0);
                tickInfo=getappdata(f,'MBESO_Fig9Tick195');
                check([id '_tick195_label_fit'],strcmp(strtrim(string(aa.XTickLabel(find(aa.XTick==195),:))),"195"),tickInfo.label_visible,0);
                expected=[string(sprintf('Material\n(total: %s)',commaInteger(F.full_transition_totals(1)))); ...
                    string(sprintf('Solid-void\n(total: %s)',commaInteger(F.full_transition_totals(2))))];
                check([id '_wrapped_legend_totals'],isequal(string(lg.String(:)),expected),true,0);
                check([id '_legend_one_column'],lg.NumColumns,1,0);
                % Check the saved bars as well as their MAT source arrays.
                barFigure=openfig(fullfile(root,'outputs','Fig09_panel_c.fig'),'new','invisible');
                barClean=onCleanup(@()close(barFigure));baseline=find(D.epsilon_MPa==0);
                material=findobj(barFigure,'Tag','Figure3_c_series_1');
                occupancy=findobj(barFigure,'Tag','Figure3_c_series_2');
                check([id '_saved_Fig09c_baseline_bars'],[material.YData(baseline) occupancy.YData(baseline)],F.full_transition_totals,0);
                clear barClean;
            else
                check([id '_ylim'],aa.YLim,[0 10],0);
                check([id '_angled_xticks'],aa.XTickLabelRotation,45,0);
                check([id '_legend_one_row'],lg.NumColumns,2,0);
                check([id '_zoom_legend'],isequal(string(lg.String(:)),["Material";"Solid-void"]),true,0);
                aa.Units='centimeters';lg.Units='centimeters';
                check([id '_legend_above_axes'],lg.Position(2)>=sum(aa.Position([2 4])),true,0);
                check([id '_zoom_sums'],[sum(F.N_TC(k)) sum(F.N_SV(k))],F.zoom_transition_totals,0);
            end
        case 'Fig09_d'
            for k=1:2,series(sprintf('Figure3_e_series_%d',k),D.layout_difference_percent(:,k));end
    end
    switch id
        case 'Fig06_d'
            captions=findall(f,'-regexp','Tag','^case_caption_');
            for t=captions'
                check([id '_' t.Tag '_italic_C'],any(contains(string(t.String),'{\it C}')),true,0);
                check([id '_' t.Tag '_tex'],strcmp(t.Interpreter,'tex'),true,0);
            end
        case 'Fig08_a'
            for tag={'Vk','nk','V1','C_Nmm'}
                h=findobj(f,'Tag',tag{1});
                check([id '_' tag{1} '_italic_variable'],contains(h.DisplayName,'{\it '),true,0);
            end
        case 'Fig08_b'
            for tag={'trace_raw_974_MPa','trace_filtered_974_MPa'}
                h=findobj(f,'Tag',tag{1});
                check([id '_' tag{1} '_italic_variable'],contains(h.DisplayName,'{\it '),true,0);
            end
        case 'Fig08_c'
            for tag={'eta_raw_974','eta_spatial_974','eta_temporal_974','eta_temporal_5829'}
                h=findobj(f,'Tag',tag{1});
                check([id '_' tag{1} '_italic_variable'],contains(h.DisplayName,'{\it '),true,0);
            end
        case 'Fig09_b'
            check([id '_italic_C'],contains(aa.YLabel.String,'{\it C}'),true,0);
            lg=findobj(f,'Type','legend');
            check([id '_italic_deadband'],contains(lg.Title.String,'{\it δ}_{\it σ}'),true,0);
        case {'Fig09_c','Fig09_d'}
            check([id '_italic_deadband'],contains(aa.XLabel.String,'{\it δ}_{\it σ}'),true,0);
        case 'Fig09_e'
            lg=findobj(f,'Type','legend');
            check([id '_italic_material_fractions'],all(contains(string(lg.String(2:3)),'{\it V}')),true,0);
    end
    if M.manuscript_figure(j)==9&&ismember(M.panel(j),["e","f_1","f_2"])
        check([id '_one_axes'],numel(aa),1,0);
        check([id '_placement_identity'],getappdata(f,'ManuscriptPlacementScale'),[1 1],1e-12);
        check([id '_source_canvas_matches_target'],getappdata(f,'ManuscriptSourceCanvasCM'),[g.width_mm g.height_mm]/10,1e-12);
        check([id '_no_crop'],[g.crop_left_fraction g.crop_top_fraction g.crop_right_fraction g.crop_bottom_fraction],zeros(1,4),0);
        expectedEnd=250;if strcmp(id,'Fig09_f_2'),expectedEnd=214;end
        check([id '_display_axis_endpoint'],aa.XLim(2),expectedEnd,0);
        check([id '_black_axes'],[aa.XColor aa.YColor],zeros(1,6),0);
        lg=findobj(f,'Type','legend');lg.Units='centimeters';lp=lg.Position;
        check([id '_legend_inside_canvas'],all(lp(1:2)>=0) && all(lp(1:2)+lp(3:4)<=f.PaperSize+1e-10),true,0);
        expectedFonts=[9 9.5 9.5 8];if strcmp(id,'Fig09_f_2'),expectedFonts=[8 8.5 8.5 7.5];end
        check([id '_fixed_font_points'],[aa.FontSize aa.XLabel.FontSize aa.YLabel.FontSize lg.FontSize],expectedFonts,1e-12);
    end
    if ismember(id,{'Fig08_a','Fig09_b','Fig09_e','Fig09_f_1'})
        check([id '_display_margin_0_250'],aa.XLim,[0 250],0);
        historyLines=findall(aa,'Type','line');
        for h=historyLines'
            if ~isempty(h.XData) && numel(h.XData)>10
                check([id '_' h.Tag '_data_ends214'],max(h.XData),214,0);
            end
        end
    end
    if M.manuscript_figure(j)==8&&ismember(M.panel(j),["b","c"])
        check([id '_no_temporary_highlight'],numel(findall(f,'-regexp','Tag','^event_')),0,0);
        check([id '_iteration_label'],strcmp(aa.XLabel.String,'Iteration'),true,0);
    end
    clear clean;
end
checks=cell2table(rows,'VariableNames',{'check','maximum_absolute_error','tolerance','passed'});
writetable(checks,fullfile(root,'output_checks.csv'));
assert(all(checks.passed),'Exported panel check failed.');
fprintf('Final exported panels: %d data and formatting checks passed.\n',height(checks));
    function series(tag,y,x)
        h=findobj(f,'Tag',tag);assert(isscalar(h),'Missing or duplicate plotted series: %s',tag);
        check([id '_' tag '_YData'],h.YData,y,0);
        if nargin==3,check([id '_' tag '_XData'],h.XData,x,0);end
    end
    function check(name,a,b,tol)
        if numel(a)~=numel(b),err=Inf;else,err=max(abs(double(a(:))-double(b(:))));end
        rows(end+1,:)={name,err,tol,err<=tol}; %#ok<AGROW>
    end
end

function text=commaInteger(value)
text=sprintf('%d',value);
for k=numel(text)-3:-3:1,text=[text(1:k) ',' text(k+1:end)];end
end

function value=plainSymbols(value)
% Remove typography commands only when checking the semantic legend text.
value=regexprep(value,'\\(?:it|rm|bf)\s*','');
value=erase(erase(value,'{'),'}');
end
