clear
clc
% close

%%

Strs_Unf = load('Fig_6b_Unfiltered.txt');
Strs_Fil = load('Fig_6b_Filtered.txt');
iteration = 1:1:10;

figure()
hold on
plot(iteration,Strs_Unf,'r-*','Linewidth',1.2,'MarkerSize',10)
plot(iteration,Strs_Fil,'b--o','Linewidth',1.2,'MarkerSize',10)

xlim([1 10])
xticks([1:1:10])
ylim([-2 8])
yticks([-2:1:8])

legend('Unfiltered ({\itσ}_{\ite,i})','Filtered ({\itσ}′_{\ite,i})','Location','Best')
xlabel('Iteration')
ylabel('Stress-state indicator (MPa)')

set(gca,'FontName','Times New Roman','FontSize',18)
set(gcf,'Position',[446   475   560   400])
grid on

