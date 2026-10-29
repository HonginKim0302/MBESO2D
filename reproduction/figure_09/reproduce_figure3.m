function reproduce_figure3()
%REPRODUCE_FIGURE3 Plot manuscript Fig. 9(b,c,d) through iteration 214.
% The five cases share one iteration horizon; their termination iterations
% need not coincide. Values are extracted from the saved experiment arrays.
% Run in MATLAB R2024b or later. No optimization is performed here.
root=fileparts(mfilename('fullpath'));L=load(fullfile(root,'data','plot_inputs_214.mat'),'P');P=L.P;
oldPath=path;pathGuard=onCleanup(@()path(oldPath)); %#ok<NASGU>
addpath(fileparts(root),'-begin');
assert(isequal(P.states,(0:214)') && isequal(P.updates,(1:214)'));
assert(isequal(size(P.C_Nmm),[215 5]) && all(P.C_Nmm(:)>0));
assert(isequal(P.C_change_same_state_percent,100*(P.C_Nmm./P.C_Nmm(:,1)-1)));
assert(isequal(P.counts_updates_2_214,[sum(P.N_TC(2:214,:),1)' sum(P.N_SV(2:214,:),1)']));
assert(isequal(size(P.final_phase_214),[6000 5]));
assert(isequal(P.layout_difference_percent,100*P.layout_difference_counts./P.layout_difference_denominators));
dirs={'figures','panels'};for j=1:numel(dirs),q=fullfile(root,dirs{j});if ~isfolder(q),mkdir(q);end,end
font='Times New Roman';font_size=9;label_size=9.5;
palette=[0 0 0;.12 .39 .65;.80 .48 0;.10 .55 .43;.48 .27 .69];
brown=[.72 .47 .10];gray=[.48 .48 .48];
canvas=[154.9 175.4];pixel_canvas=[915 1036];
boxes=[95 338 425 588;553 338 883 588;95 708 425 958;553 708 883 958];
positions=zeros(4,4);
for j=1:4,b=boxes(j,:);positions(j,:)=[b(1)/pixel_canvas(1)*canvas(1), ...
    (pixel_canvas(2)-b(4))/pixel_canvas(2)*canvas(2),(b(3)-b(1))/pixel_canvas(1)*canvas(1),(b(4)-b(2))/pixel_canvas(2)*canvas(2)];end
checks={};dimensions={};artifacts={};
f=new_figure('Figure3_deadband',canvas);
for j=[1 2 4],ax=make_panel(f,positions(j,:),char('a'+j),font_size,label_size);validate_panel(ax,char('a'+j),'main');end
save_artifact(f,fullfile(root,'figures','Figure3_deadband'),'combined','b,c,e; common horizon 0 to 214',canvas);
% Each standalone panel retains exactly the main figure's physical plot box.
for j=[1 2 4]
    panel=char('a'+j);plot_size=positions(j,3:4);margins=[16 12 4 5];
    sz=[plot_size(1)+margins(1)+margins(3),plot_size(2)+margins(2)+margins(4)];
    name=['Figure3' panel];f=new_figure(name,sz);pos=[margins(1:2) plot_size];
    ax=make_panel(f,pos,panel,font_size,label_size);validate_panel(ax,panel,'standalone');
    save_artifact(f,fullfile(root,'panels',name),'standalone',panel,sz);
end
% No post-214 panel, inset or continuation composite is generated.
write17(cell2table(checks,'VariableNames',{'artifact','check','maximum_absolute_error','tolerance','passed'}),fullfile(root,'verification_checks.csv'));
write17(cell2table(dimensions,'VariableNames',{'artifact','panel','canvas_width_mm','canvas_height_mm','axes_left_mm','axes_bottom_mm','axes_width_mm','axes_height_mm'}),fullfile(root,'panel_dimensions.csv'));
write17(cell2table(artifacts,'VariableNames',{'artifact','kind','panel','fig','png','pdf','canvas_width_mm','canvas_height_mm'}),fullfile(root,'artifact_manifest.csv'));
assert(all(cell2mat(checks(:,5))),'A render-array assertion failed.');
mbeso_finalize_paper_exports(root);
fprintf('Figure 3: %d numerical and format assertions passed; 3 panels and 1 overview exported.\n',size(checks,1));

    function f=new_figure(name,sz)
        f=figure('Visible','off','Color','w','Name',name,'NumberTitle','off', ...
            'Units','centimeters','Position',[1 1 sz/10],'Renderer','painters', ...
            'DefaultAxesFontName',font,'DefaultTextFontName',font, ...
            'DefaultAxesFontSize',font_size,'DefaultTextFontSize',font_size);
        set(f,'PaperUnits','centimeters','PaperSize',sz/10,'PaperPosition',[0 0 sz/10],'PaperPositionMode','manual','InvertHardcopy','off');
        setappdata(f,'Figure3Provenance',struct('source','data/plot_inputs_214.mat','C_definition',P.C_definition, ...
            'transition_definition',P.transition_definition,'layout_definition',P.layout_definition, ...
            'index_definition',P.index_definition,'zero_definition',P.zero_definition, ...
            'comparison_horizon',214,'first_termination_iterations',P.first_stop));
    end
    function ax=make_panel(f,pos,panel,fs,ls)
        ax=axes('Parent',f,'Units','centimeters','Position',pos/10,'Tag',['Figure3_' panel]);style_axes(ax,fs);hold(ax,'on');
        if panel=='b'
            for k=1:5
                h=plot(ax,P.states,P.C_change_same_state_percent(:,k),'Color',palette(k,:),'LineWidth',.9);
                h.Tag=['Figure3_b_' P.run_ids{k}];h.DisplayName=P.labels{k};
            end
            xlim(ax,[0 214]);xticks(ax,[0 50 100 150 214]);ylim(ax,[-40 40]);yticks(ax,-40:20:40);
            xlabel(ax,'Iteration','FontName',font,'FontSize',ls);
            ylabel(ax,'C change (%)','FontName',font,'FontSize',ls);
            lg=legend(ax,P.labels,'Location','southeast','Box','off','FontName',font,'FontSize',8,'NumColumns',2);
            lg.ItemTokenSize=[12 8];
            lg.Title.String=[char(948) '_' char(963) ' (MPa)'];lg.Title.FontName=font;lg.Title.FontSize=8;lg.Title.FontWeight='normal';
        else
            switch panel
                case 'c',Y=P.counts_updates_2_214;lims=[0 8000];ticks=0:2000:8000;names={'Material','Solid-void'};colors=[brown;gray];
                case 'e',Y=P.layout_difference_percent;lims=[0 10];ticks=0:2:10;names={'Solid-void domain','Material common solids'};colors=[gray;brown];
            end
            bb=bar(ax,1:5,Y,'grouped','BarWidth',.82);
            for k=1:2,bb(k).FaceColor=colors(k,:);bb(k).EdgeColor='none';bb(k).Tag=sprintf('Figure3_%s_series_%d',panel,k);end
            xlim(ax,[.45 5.55]);xticks(ax,1:5);xticklabels(ax,{'0','.005','.05','.5','5'});ylim(ax,lims);yticks(ax,ticks);
            xlabel(ax,[char(948) '_' char(963) ' (MPa)'],'FontName',font,'FontSize',ls);
            if panel=='e',yl='Different elements (%)';else,yl='Transition events';end
            ylabel(ax,yl,'FontName',font,'FontSize',ls);
            lg=legend(ax,bb,names,'Location','northeast','Box','off','FontName',font,'FontSize',8);
            lg.ItemTokenSize=[10 8];
        end
        allfont=findall(f,'-property','FontName');set(allfont,'FontName',font);
        set(ax,'Position',pos/10);drawnow;
        setappdata(ax,'Figure3Panel',panel);
        setappdata(ax,'SourceValueDefinition',P.C_definition);
        if panel=='c',setappdata(ax,'SourceValueDefinition',P.count_definition);end
        if panel=='e',setappdata(ax,'SourceValueDefinition',P.layout_definition);end
        record_dimensions(ax,f.Name,panel,f.Position(3:4)*10);
    end
    function style_axes(ax,fs)
        set(ax,'FontName',font,'FontSize',fs,'LineWidth',.6,'Box','off','TickDir','out', ...
            'XColor','k','YColor','k','Color','w','PositionConstraint','innerposition', ...
            'GridColor',[.78 .78 .78],'GridAlpha',.5,'GridLineStyle','-');
        set(ax,'XGrid','off','YGrid','on');
    end
    function validate_panel(ax,panel,kind)
        id=[kind '_' panel];check(id,'no_panel_title',isempty(ax.Title.String),true,0);
        if panel=='b'
            for k=1:5
                h=findobj(ax,'Tag',['Figure3_b_' P.run_ids{k}]);assert(isscalar(h));
                check(id,['X_' P.run_ids{k}],h.XData,P.states',0);
                check(id,['Y_' P.run_ids{k}],h.YData,P.C_change_same_state_percent(:,k)',0);
            end
        else
            if panel=='c',Y=P.counts_updates_2_214;else,Y=P.layout_difference_percent;end
            for k=1:2
                h=findobj(ax,'Tag',sprintf('Figure3_%s_series_%d',panel,k));assert(isscalar(h));
                check(id,sprintf('bar_%d_X',k),h.XData,1:5,0);
                check(id,sprintf('bar_%d_Y',k),h.YData,Y(:,k)',0);
            end
        end
        allfont=findall(ax,'-property','FontName');check(id,'all_axes_fonts_Times_New_Roman',all(strcmp(get_font_names(allfont),font)),true,0);
    end
    function names=get_font_names(h)
        names=cell(numel(h),1);for i=1:numel(h),names{i}=h(i).FontName;end
    end
    function record_dimensions(ax,id,panel,sz)
        ax.Units='centimeters';v=ax.Position*10;dimensions(end+1,:)={id,panel,sz(1),sz(2),v(1),v(2),v(3),v(4)};
    end
    function save_artifact(f,stem,kind,panel,sz)
        mbeso_black_text(f);
        mbeso_style_bar_charts(f);
        drawnow;allfont=findall(f,'-property','FontName');set(allfont,'FontName',font);
        savefig(f,[stem '.fig']);
        % Retain the full PNG canvas and embed actual TNR fonts in vector PDF.
        print(f,[stem '.png'],'-dpng','-r600');
        pdfmeta=export_exact_tnr_pdf(f,[stem '.pdf']);
        mbeso_export_emf(f,[stem '.emf']);
        fid=fopen([stem '_pdf_metadata.json'],'w','n','UTF-8');fprintf(fid,'%s',jsonencode(pdfmeta));fclose(fid);
        [~,name]=fileparts(stem);rel=strrep(stem,[root filesep],'');rel=strrep(rel,'\','/');
        artifacts(end+1,:)={name,kind,panel,[rel '.fig'],[rel '.png'],[rel '.pdf'],sz(1),sz(2)};
        close(f);
    end

    function check(id,name,actual,expected,tolerance)
        assert(isequal(size(actual),size(expected)) || (isscalar(actual)&&isscalar(expected)));
        error=max(abs(double(actual(:))-double(expected(:))),[],'all');
        checks(end+1,:)={id,name,error,tolerance,isfinite(error)&&error<=tolerance};
    end
end

function write17(T,file)
fid=fopen(file,'w','n','UTF-8');assert(fid>=0);clean=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',strjoin(T.Properties.VariableNames,','));
for i=1:height(T)
    items=cell(1,width(T));
    for j=1:width(T)
        v=T{i,j};if iscell(v),v=v{1};end
        if isnumeric(v)||islogical(v),items{j}=sprintf('%.17g',double(v));
        else,items{j}=['"' strrep(char(string(v)),'"','""') '"'];end
    end
    fprintf(fid,'%s\n',strjoin(items,','));
end
end
