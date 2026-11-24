function res = run_experiments(P,outdir)
%RUN_EXPERIMENTS  All experiments of the study. Returns a results struct (also saved to outdir/results.mat).
%   E1  key rate & QBER vs. distance (static vs fading-adaptive decoy intensity)
%   E2  classical-link BER / outage vs. distance
%   E3  slice-level time-domain simulation: 3 turbulence levels x 3 schemes x P.nseeds realisations
%   E4  key-demand sweep (when does QoS-aware key allocation start to matter?)
if nargin < 2, outdir = 'results'; end
if ~exist(outdir,'dir'), mkdir(outdir); end
lut = build_qkd_lut(P);  res.lut = lut;  res.P = P;
nT = numel(P.turb.Cn2);

%% ---------- E1 / E2: distance sweeps (i.i.d. fading draws, 30k samples per point) ----------
Ls = 500:250:5000; Ns = 30000; res.Ls = Ls;
res.e1.key_static = zeros(nT,numel(Ls)); res.e1.key_adapt = res.e1.key_static; res.e1.qber = res.e1.key_static;
res.e1.loss_dB = zeros(nT,numel(Ls));
res.e2.Qbar = zeros(nT,numel(Ls)); res.e2.out_fix = res.e2.Qbar; res.e2.out_min = res.e2.Qbar; res.e2.ber = res.e2.Qbar;
set_seed(7);
for it = 1:nT
    Cn2 = P.turb.Cn2(it);
    for il = 1:numel(Ls)
        L = Ls(il);
        [aq,bq] = gg_params(Cn2,P.q.lambda,L,2*P.q.a_rx);
        [ac,bc] = gg_params(Cn2,P.c.lambda,L,2*P.c.a_rx);
        Iq = gg_fading(aq,bq,randn(Ns,1),randn(Ns,1));
        Ic = gg_fading(ac,bc,randn(Ns,1),randn(Ns,1));
        eta0 = quantum_budget(P,L,Cn2);
        [rs,es] = lut_eval(lut,eta0*Iq,false);  ra = lut_eval(lut,eta0*Iq,true);
        res.e1.key_static(it,il) = mean(rs)*P.q.rate*P.q.duty;
        res.e1.key_adapt(it,il)  = mean(ra)*P.q.rate*P.q.duty;
        w = rs > 0; if any(w), res.e1.qber(it,il) = sum(es(w).*rs(w))/sum(rs(w)); else, res.e1.qber(it,il) = NaN; end
        res.e1.loss_dB(it,il) = -10*log10(eta0);
        Qb = classical_budget(P,L,Cn2);
        res.e2.Qbar(it,il) = Qb;
        res.e2.ber(it,il)  = mean(ook_ber(Qb*Ic));
        res.e2.out_fix(it,il) = mean(ook_ber(Qb*Ic) > P.c.ber_fec);                       % 10 Gb/s
        res.e2.out_min(it,il) = mean(ook_ber(Qb*Ic*sqrt(1e10/P.c.rates(1))) > P.c.ber_fec); % 1.25 Gb/s floor rate
    end
end

%% ---------- E3: slice-level time-domain simulation ----------
nS = numel(P.schemes);
res.slice = cell(nT,nS); res.ts = cell(nT,nS);
for it = 1:nT
    runs = cell(nS,P.nseeds);
    for is = 1:P.nseeds
        env = gen_environment(P,it,100*it+is,P.L);
        for k = 1:nS
            runs{k,is} = run_scheme(P,env,lut,P.schemes(k));
        end
        if is == 1, for k = 1:nS, res.ts{it,k} = runs{k,1}.ts; end, end
    end
    for k = 1:nS
        res.slice{it,k} = avg_structs(runs(k,:));
    end
    printf('  E3 turbulence %s done\n',P.turb.names{it}); fflush(stdout);
end

%% ---------- E4: key-demand sweep at moderate turbulence (keys only) ----------
scales = [0.5 1 1.5 2 3 4]; res.e4.scales = scales; it = 2;
res.e4.sat = zeros(numel(scales),3,2); res.e4.wait99 = res.e4.sat; res.e4.tot_sat = zeros(numel(scales),2);
Pk = P;
for isc = 1:numel(scales)
    Pk.sl.key_demand_scale = scales(isc);
    acc = cell(2,P.nseeds);
    for is = 1:P.nseeds
        env = gen_environment(Pk,it,500+is,P.L);
        for k = 1:2
            acc{k,is} = run_scheme(Pk,env,lut,P.schemes(k+1),true);
        end
    end
    for k = 1:2
        mm = cellfun(@(s) s.key_sat,acc(k,:),'UniformOutput',false);       res.e4.sat(isc,:,k)    = mean(cell2mat(mm(:)),1);
        mm = cellfun(@(s) s.key_wait_p99_ms,acc(k,:),'UniformOutput',false); res.e4.wait99(isc,:,k) = mean(cell2mat(mm(:)),1);
        td = cellfun(@(s) sum(s.key_serv_bps)/sum(s.key_dem_bps),acc(k,:)); res.e4.tot_sat(isc,k) = mean(td);
    end
end
printf('  E4 done\n');

save('-mat',fullfile(outdir,'results.mat'),'res');
write_summary_csv(P,res,outdir);
end
