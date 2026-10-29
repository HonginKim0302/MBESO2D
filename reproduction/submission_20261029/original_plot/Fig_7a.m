clear
clc
% close

%%
SolidVol = load('Fig_7a_SolidVol.txt');
TensVol = load('Fig_7a_TensVol.txt');
CompVol = load('Fig_7a_CompVol.txt');
iteration = 1:1:214;

figure()
hold on
plot(iteration,SolidVol,'k-.','Linewidth',1.2)
plot(iteration,TensVol,'b-','Linewidth',1.2)
plot(iteration,CompVol,'r--','Linewidth',1.2)

xlabel('Iteration')
legend('Solid ({\itV}_1+{\itV}_2)','Tensile material ({\itV}_1)','Compressive material ({\itV}_2)','Location','Northeast')
ylim([0 100])
yticks([0:20:100])
ylabel('Volume fraction (%)')

set(gca,'FontName','Times New Roman','FontSize',18)
set(gcf,'Position',[446   475   560   400])
grid on