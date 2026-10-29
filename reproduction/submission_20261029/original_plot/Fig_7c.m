clear
clc
close

%%
Deadband = load('Fig_7c_Deadband.txt');
iteration = 0:1:214;

figure()
hold on
plot(iteration,Deadband(:,1),'k-.','Linewidth',1.2)
plot(iteration,Deadband(:,2),'b-','Linewidth',1.2)
plot(iteration,Deadband(:,3),'r--','Linewidth',1.2)
plot(iteration,Deadband(:,4),'m-','Linewidth',1.2)
plot(iteration,Deadband(:,5),'g-','Linewidth',1.2)
xlabel('Iteration')
legend('{\it\delta}_{\it\sigma} = 0','{\it\delta}_{\it\sigma} = 0.005','{\it\delta}_{\it\sigma} = 0.05','{\it\delta}_{\it\sigma} = 0.5','{\it\delta}_{\it\sigma} = 5','NumColumns',2,'Location','Northeast')
ylim([-40 40])
yticks([-40:10:40])
ylabel('Compliance difference (%)')
set(gca,'FontName','Times New Roman','FontSize',18)
set(gcf,'Position',[446   475   560   400])
grid on


figure()
hold on
plot(iteration,Deadband(:,1),'k-.','Linewidth',2)
plot(iteration,Deadband(:,2),'b-','Linewidth',2)
plot(iteration,Deadband(:,3),'r--','Linewidth',2)
plot(iteration,Deadband(:,4),'m-','Linewidth',2)
plot(iteration,Deadband(:,5),'g-','Linewidth',2)
% xlabel('Iteration')
% legend('{\it\delta}_{\it\sigma} = 0','{\it\delta}_{\it\sigma} = 0.005','{\it\delta}_{\it\sigma} = 0.05','{\it\delta}_{\it\sigma} = 0.5','{\it\delta}_{\it\sigma} = 5','NumColumns',2,'Location','Northeast')
xlim([195 215])
yticks([-1.5:0.5:1.5])
ylim([-1.5 1.5])
% ylabel('Compliance change (%)')
set(gca,'FontName','Times New Roman','FontSize',24)
set(gcf,'Position',[446   475   560   300])
grid on


figure()
hold on
plot(iteration,Deadband(:,1),'k-.','Linewidth',1.2)
plot(iteration,Deadband(:,2),'b-','Linewidth',1.2)
plot(iteration,Deadband(:,3),'r--','Linewidth',1.2)
plot(iteration,Deadband(:,4),'m-','Linewidth',1.2)
plot(iteration,Deadband(:,5),'g-','Linewidth',1.2)
xlabel('Iteration')
legend('{\it\delta}_{\it\sigma} = 0 MPa','{\it\delta}_{\it\sigma} = 0.005 MPa','{\it\delta}_{\it\sigma} = 0.05 MPa','{\it\delta}_{\it\sigma} = 0.5 MPa','{\it\delta}_{\it\sigma} = 5 MPa','NumColumns',2,'Location','Northeast')
ylim([-40 40])
yticks([-40:10:40])
ylabel('Compliance difference (%)')
set(gca,'FontName','Times New Roman','FontSize',18)
set(gcf,'Position',[446   475   560   400])
grid on
