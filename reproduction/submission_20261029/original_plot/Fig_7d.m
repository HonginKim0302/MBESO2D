clear
clc
close

%%

Deadband = {'0','0.005','0.05','0.5','5'};
Transition = [5200 5725; 5392 6607; 5360 5770; 5000 4734; 5138 4033];
TransColors = [1 0 0; 0 1 0];

x = 1:5;
hBar = bar(x,Transition,0.8);
hBar(1).FaceColor = TransColors(1,:);
hBar(2).FaceColor = TransColors(2,:);
ylim([3000 8000]);

ax = gca;
ax.XTick = x;
ax.XTickLabels = Deadband;

legend([hBar(1), hBar(2)],{'Solid–void','Tensile–compressive'},'Location','best');

xlabel('Deadband half-width (MPa)')
ylabel('Cumulative transition events')
set(gca,'FontName','Times New Roman','FontSize',18)
set(gcf,'Position',[446   475   560   400])
grid on

for i = 1:numel(hBar)
    xPos = hBar(i).XEndPoints;
    yPos = hBar(i).YEndPoints;

    text(xPos, yPos, compose('%d', hBar(i).YData), ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'FontName', 'Times New Roman', ...
        'FontSize', 18, ...
        'Color', 'k');
end



