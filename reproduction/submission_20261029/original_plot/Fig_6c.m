clear
clc
close

%%
Score_974 = load('Fig_6c_Score974.txt');
Score_5829 = load('Fig_6c_Score5829.txt');
Threshold = load('Fig_6c_Threshold.txt');
iteration = 1:1:10;

figure()
hold on
plot(iteration,Score_974,'r-^','Linewidth',1.2,'MarkerSize',10)
plot(iteration,Score_5829,'b-o','Linewidth',1.2,'MarkerSize',10)
plot(iteration,Threshold,'k--','Linewidth',1.2,'MarkerSize',10)

xlim([1 10])
xticks([1:1:10])
% ylim([-2 8])
% yticks([-2:1:8])

legend('Element 974','Element 5829','Retention threshold','Location','Best')
xlabel('Iteration')
ylabel('History-averaged utilization')

set(gca,'FontName','Times New Roman','FontSize',18)
set(gcf,'Position',[446   475   560   400])
grid on

