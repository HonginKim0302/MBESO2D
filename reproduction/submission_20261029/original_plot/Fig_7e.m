clear
clc
close

%%

Deadband = {'0','0.005','0.05','0.5','5'};
Elem_Diff = [0	0; 1.86666666666667 0.170648464163823; 1 0.126582278481013; 1.86666666666667 0.383959044368601; 8.33333333333333 1.44186046511628];
TransColors = [1 0 0; 0 1 0];

x = 1:5;
hBar = bar(x,Elem_Diff,0.8);
hBar(1).FaceColor = TransColors(1,:);
hBar(2).FaceColor = TransColors(2,:);
% ylim([0 10]);

ax = gca;
ax.XTick = x;
ax.XTickLabels = Deadband;

legend([hBar(1), hBar(2)],{'Solid–void','Tensile–compressive'},'Location','best');

xlabel('Deadband half-width (MPa)')
ylabel('Layout difference (%)')
set(gca,'FontName','Times New Roman','FontSize',18)
set(gcf,'Position',[446   475   560   400])
grid on

for i = 1:numel(hBar)
    xPos = hBar(i).XEndPoints;
    yPos = hBar(i).YEndPoints;
    values = hBar(i).YData;

    labels = compose('%.2f', values);
    labels(values == 0) = {'0'};

    text(xPos, yPos, labels, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'FontName', 'Times New Roman', ...
        'FontSize', 18, ...
        'Color', 'k');
end

