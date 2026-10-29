clear
clc
% close

%%
C = load('Fig_6a_C.txt');
nk = load('Fig_6a_nk.txt');
iteration = 0:1:214;

figure()
hold on
plot(iteration,C,'r-','Linewidth',1.2)
yyaxis left
xlabel('Iteration')
ylabel('Compliance (N·mm)')
ylim([0 800])
yticks([0:100:800])
yyaxis right
plot(iteration,nk,'b-.','Linewidth',1.2)

legend('Compliance (\itC)','Normalization coefficient ({\itn}_{\itk})','Location','Southeast')
ylabel('Normalization coefficient')
ylim([0 8])
yticks([0:1:8])
set(gca,'ycolor','k') 

set(gca,'FontName','Times New Roman','FontSize',18)
set(gcf,'Position',[446   475   560   400])
grid on