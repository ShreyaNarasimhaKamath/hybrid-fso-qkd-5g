function print_report(P,res)
%PRINT_REPORT  Console summary of the headline numbers.
printf('\n================ HEADLINE RESULTS (L = %.1f km) ================\n',P.L/1e3);
for it = 1:numel(P.turb.Cn2)
    printf('\n--- %s turbulence ---\n',P.turb.names{it});
    for k = 1:numel(P.schemes)
        m = res.slice{it,k};
        printf('%-17s key %6.0f kb/s QBER %4.1f%% | goodput %.2f Gb/s (p5 %.2f, CoV %.2f) | URLLC SLA %.2f%% e2e-p99 %.2f ms | eMBB SLA %.1f%% | mMTC SLA %.1f%% | key served U/E/M = %.0f/%.0f/%.0f%%\n',...
            P.schemes(k).name,m.key_gen_bps/1e3,100*m.qber,m.link_good_mean/1e9,m.link_good_p5/1e9,m.link_good_cov,...
            100*m.sla(1),m.e2e_p99_ms(1),100*m.sla(2),100*m.sla(3),100*m.key_sat);
    end
end
end
