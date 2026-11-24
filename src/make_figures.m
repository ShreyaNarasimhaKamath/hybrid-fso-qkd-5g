function make_figures(P,res,outdir)
%MAKE_FIGURES  Produce all result figures as PNG in outdir.
tc = [0.12 0.47 0.71; 0.95 0.55 0.10; 0.80 0.15 0.15];       % turbulence colours (weak, moderate, strong)
sc = [0.55 0.55 0.55; 0.95 0.65 0.20; 0.10 0.60 0.35];       % scheme colours (traditional, static, QoS-aware)
nT = numel(P.turb.Cn2); Ls = res.Ls/1e3;
fs = 11;
newfig = @() figure('visible','off','position',[100 100 1100 420]);
save_fig = @(h,name) print(h,fullfile(outdir,name),'-dpng','-r110');

%% Fig 1: secret key rate and QBER vs distance
h = newfig();
subplot(1,2,1); hold on;
for it = 1:nT
    semilogy(Ls,max(res.e1.key_adapt(it,:),1)/1e3,'-','color',tc(it,:),'linewidth',2);
end
for it = 1:nT
    semilogy(Ls,max(res.e1.key_static(it,:),1)/1e3,'--','color',tc(it,:),'linewidth',1.5);
end
set(gca,'yscale','log'); grid on; ylim([0.1 1e4]);
xlabel('Link distance (km)'); ylabel('Secret key rate (kb/s)');
title('Decoy-state BB84 over FSO (850 nm, daylight)');
legend([cellfun(@(s) [s ' turb., adaptive'],P.turb.names,'uniformoutput',false), ...
        cellfun(@(s) [s ' turb., fixed mu'],P.turb.names,'uniformoutput',false)],'location','northeast','fontsize',8);
set(gca,'fontsize',fs);
subplot(1,2,2); hold on;
for it = 1:nT, plot(Ls,100*res.e1.qber(it,:),'-','color',tc(it,:),'linewidth',2); end
grid on; xlabel('Link distance (km)'); ylabel('QBER (%)'); title('Quantum bit error rate (key-weighted)');
legend(P.turb.names,'location','northwest'); set(gca,'fontsize',fs);
save_fig(h,'fig1_key_rate_vs_distance'); close(h);

%% Fig 2: classical link
h = newfig();
subplot(1,2,1); hold on;
for it = 1:nT, plot(Ls,10*log10(res.e2.Qbar(it,:).^2),'-','color',tc(it,:),'linewidth',2); end
grid on; xlabel('Link distance (km)'); ylabel('Mean electrical SNR, 10 Gb/s (dB)');
title('1550 nm OOK link budget'); legend(P.turb.names); set(gca,'fontsize',fs);
subplot(1,2,2); hold on;
for it = 1:nT, plot(Ls,max(res.e2.out_fix(it,:),1e-5),'-','color',tc(it,:),'linewidth',2); end
for it = 1:nT, plot(Ls,max(res.e2.out_min(it,:),1e-5),'--','color',tc(it,:),'linewidth',1.5); end
set(gca,'yscale','log'); grid on; ylim([1e-5 1]); xlabel('Link distance (km)'); ylabel('Frame-loss (outage) probability');
title('Fixed 10 Gb/s (solid) vs. AMC floor rate 1.25 Gb/s (dashed)'); set(gca,'fontsize',fs);
save_fig(h,'fig2_classical_link'); close(h);

%% Fig 3: key satisfaction per slice
h = newfig();
for it = 1:nT
    subplot(1,nT,it);
    Y = 100*[res.slice{it,2}.key_sat; res.slice{it,3}.key_sat]';
    hb = bar(Y,'grouped'); set(hb(1),'facecolor',sc(2,:)); set(hb(2),'facecolor',sc(3,:));
    set(gca,'xtick',1:3,'xticklabel',P.sl.names); ylim([0 118]); grid on;
    title(sprintf('%s turbulence (key supply %.0f kb/s)',P.turb.names{it},res.slice{it,3}.key_gen_bps/1e3));
    if it == 1, ylabel('Key demand served (%)'); legend({'Hybrid (static)','Hybrid QoS-aware'},'location','north'); end
    set(gca,'fontsize',fs-1);
end
save_fig(h,'fig3_key_satisfaction'); close(h);

%% Fig 4: P99 end-to-end latency per slice (markers; black bars = slice latency budget)
h = newfig(); mk = {'o','s','d'};
for it = 1:nT
    subplot(1,nT,it); hold on;
    for k = 1:3
        y = max(res.slice{it,k}.e2e_p99_ms(:),0.05);
        semilogy((1:3)+(k-2)*0.22,y,mk{k},'color',sc(k,:),'markerfacecolor',sc(k,:),'markersize',9);
    end
    for s = 1:3, line([s-0.38 s+0.38],P.sl.budget_ms(s)*[1 1],'color',[0 0 0],'linewidth',3); end
    set(gca,'yscale','log','xtick',1:3,'xticklabel',P.sl.names); xlim([0.5 3.5]); ylim([0.1 2e4]); grid on;
    title(sprintf('%s turbulence',P.turb.names{it}));
    if it == 1, ylabel('P99 end-to-end latency (ms)'); legend({P.schemes.name,'budget'},'location','northwest'); end
    set(gca,'fontsize',fs-1);
end
save_fig(h,'fig4_latency_p99'); close(h);

%% Fig 5: SLA compliance + link stability
h = newfig();
subplot(1,2,1); hold on;
Y = zeros(nT,3); for it = 1:nT, for k = 1:3, Y(it,k) = 100*res.slice{it,k}.sla(1); end, end
hb = bar(Y,'grouped'); for k = 1:3, set(hb(k),'facecolor',sc(k,:)); end
set(gca,'xtick',1:3,'xticklabel',P.turb.names); grid on; ylim([0 112]); ylabel('URLLC SLA met (% of 0.25 ms slots)');
title('URLLC: latency < 1 ms and no loss'); legend({P.schemes.name},'location','north'); set(gca,'fontsize',fs);
subplot(1,2,2); hold on;
Y = zeros(nT,3); for it = 1:nT, for k = 1:3, Y(it,k) = 100*res.slice{it,k}.thr_ratio_p5; end, end
hb = bar(Y,'grouped'); for k = 1:3, set(hb(k),'facecolor',sc(k,:)); end
set(gca,'xtick',1:3,'xticklabel',P.turb.names); grid on; ylabel('Delivered / offered traffic, 5th pct (%)'); ylim([0 105]);
title('Throughput stability over 10 ms windows'); set(gca,'fontsize',fs);
save_fig(h,'fig5_sla_and_stability'); close(h);

%% Fig 6: time series, strong turbulence
h = figure('visible','off','position',[100 100 1100 800]); it = nT;
T1 = res.ts{it,1}; T3 = res.ts{it,3}; T2 = res.ts{it,2};
i1 = 1:round(1/P.dt); t = T1.t(i1);
subplot(4,1,1); plot(t,T1.Ic(i1),'color',[0.3 0.3 0.8]); hold on; plot(t,T1.Iq(i1),'color',[0.8 0.3 0.3]); grid on;
ylabel('Irradiance I'); legend({'1550 nm','850 nm'},'location','northeast'); title('Strong turbulence, 3 km - 1 s excerpt'); set(gca,'fontsize',fs-1);
subplot(4,1,2); plot(t,T3.kr(i1)/1e3,'color',sc(3,:),'linewidth',1.2); grid on; ylabel('Key rate (kb/s)'); set(gca,'fontsize',fs-1);
subplot(4,1,3); plot(t,T1.rs(i1)/1e9,'color',sc(1,:),'linewidth',1.5); hold on; plot(t,T3.rs(i1)/1e9,'color',sc(3,:),'linewidth',1.5);
grid on; ylabel('Line rate (Gb/s)'); legend({'Fixed','AMC'},'location','southeast'); set(gca,'fontsize',fs-1); ylim([0 11]);
subplot(4,1,4); semilogy(t,T1.e2e(i1,1)*1e3,'color',sc(1,:)); hold on; semilogy(t,T2.e2e(i1,1)*1e3,'color',sc(2,:)); semilogy(t,T3.e2e(i1,1)*1e3,'color',sc(3,:),'linewidth',1.2);
plot([t(1) t(end)],[1 1],'k--'); grid on; ylabel('URLLC latency (ms)'); xlabel('Time (s)'); ylim([0.1 3000]);
legend({P.schemes.name,'1 ms budget'},'location','northeast'); set(gca,'fontsize',fs-1);
save_fig(h,'fig6_timeseries_strong'); close(h);

%% Fig 7: key-demand sweep
h = newfig(); sc4 = res.e4.scales;
subplot(1,2,1); hold on;
plot(sc4,100*res.e4.sat(:,1,1),'--s','color',sc(2,:),'linewidth',1.5); plot(sc4,100*res.e4.sat(:,1,2),'-s','color',sc(3,:),'linewidth',2);
plot(sc4,100*res.e4.sat(:,2,1),'--o','color',sc(2,:),'linewidth',1.5); plot(sc4,100*res.e4.sat(:,2,2),'-o','color',sc(3,:),'linewidth',2);
grid on; xlabel('Key demand (x nominal)'); ylabel('Key demand served (%)'); ylim([0 105]);
title('URLLC (squares) and eMBB (circles), moderate turbulence');
legend({'URLLC static','URLLC QoS-aware','eMBB static','eMBB QoS-aware'},'location','southwest'); set(gca,'fontsize',fs);
subplot(1,2,2); hold on;
semilogy(sc4,max(res.e4.wait99(:,1,1),0.1),'--s','color',sc(2,:),'linewidth',1.5); semilogy(sc4,max(res.e4.wait99(:,1,2),0.1),'-s','color',sc(3,:),'linewidth',2);
set(gca,'yscale','log'); plot([sc4(1) sc4(end)],[1 1],'k--'); grid on;
xlabel('Key demand (x nominal)'); ylabel('URLLC key-wait P99 (ms)'); title('Waiting for a fresh key (1 ms = whole URLLC budget)');
legend({'static','QoS-aware','1 ms budget'},'location','northwest'); set(gca,'fontsize',fs);
save_fig(h,'fig7_key_demand_sweep'); close(h);
end
