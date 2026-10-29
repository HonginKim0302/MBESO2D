clear
clc
close

%%
Elem_TC = load('Fig_7b_N_TC.txt');
Elem_SV = load('Fig_7b_N_SV.txt');
iteration = 1:214;

figure()
hold on
plot(iteration,Elem_SV,'r--','Linewidth',1.2)
plot(iteration,Elem_TC,'b-','Linewidth',1.2)
xlabel('Iteration')
legend('Solid–void','Tensile–compressive','Location','Northeast')
ylabel('Element transitions')
set(gca,'FontName','Times New Roman','FontSize',18)
set(gcf,'Position',[446   475   560   400])
grid on

figure()
hold on
plot(iteration,Elem_SV,'r--','Linewidth',1.5)
plot(iteration,Elem_TC,'b-','Linewidth',1.5)
% xlabel('Iteration')
% legend('Tensile–Compressive','Solid–Void','Location','Northeast')
xlim([195 215])
yticks([0:2:10])
% ylim([-1.5 1.5])
% ylabel('Element transition')
set(gca,'FontName','Times New Roman','FontSize',24)
set(gcf,'Position',[446   475   560   300])
grid on