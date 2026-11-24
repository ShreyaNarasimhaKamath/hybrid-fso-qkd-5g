function write_summary_csv(P,res,outdir)
%WRITE_SUMMARY_CSV  Flat tables of the slice-level results for use in reports / spreadsheets.
f = fopen(fullfile(outdir,'summary_slices.csv'),'w');
fprintf(f,'turbulence,scheme,slice,key_demand_kbps,key_served_kbps,key_satisfaction,key_wait_p99_ms,classical_throughput_Mbps,loss_ratio,queue_delay_p99_ms,e2e_delay_p99_ms,e2e_budget_ms,sla_met\n');
for it = 1:numel(P.turb.Cn2)
  for k = 1:numel(P.schemes)
    m = res.slice{it,k};
    for s = 1:3
      fprintf(f,'%s,%s,%s,%.1f,%.1f,%.4f,%.3f,%.2f,%.5f,%.3f,%.3f,%g,%.5f\n',P.turb.names{it},P.schemes(k).name,P.sl.names{s},...
        m.key_dem_bps(s)/1e3,m.key_serv_bps(s)/1e3,m.key_sat(s),m.key_wait_p99_ms(s),m.thr_bps(s)/1e6,m.loss_ratio(s),...
        m.cdelay_p99_ms(s),m.e2e_p99_ms(s),P.sl.budget_ms(s),m.sla(s));
    end
  end
end
fclose(f);
f = fopen(fullfile(outdir,'summary_links.csv'),'w');
fprintf(f,'turbulence,scheme,secure_key_rate_kbps,mean_QBER,key_wasted_frac,link_goodput_Gbps,goodput_CoV,goodput_p5_Gbps,frame_loss_time_frac,thr_ratio_p5_10ms,mean_BER\n');
for it = 1:numel(P.turb.Cn2)
  for k = 1:numel(P.schemes)
    m = res.slice{it,k};
    fprintf(f,'%s,%s,%.1f,%.4f,%.3f,%.3f,%.3f,%.3f,%.4f,%.4f,%.3e\n',P.turb.names{it},P.schemes(k).name,m.key_gen_bps/1e3,m.qber,...
        m.key_waste_frac,m.link_good_mean/1e9,m.link_good_cov,m.link_good_p5/1e9,m.link_fer_frac,m.thr_ratio_p5,m.ber_mean);
  end
end
fclose(f);
end
