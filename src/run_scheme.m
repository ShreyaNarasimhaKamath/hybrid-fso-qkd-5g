function m = run_scheme(P,env,lut,sc,keys_only)
%RUN_SCHEME  Simulate one operating scheme on one environment realisation and return all metrics.
if nargin < 5, keys_only = false; end
N = P.N; dt = P.dt; T = N*dt; sl = P.sl;
m.scheme = sc.name;

% ======================= quantum / key side =======================
if sc.qkd
    eta = env.eta0*env.Iq;
    [rpp,E] = lut_eval(lut,eta,sc.adapt);
    kr  = rpp*P.q.rate*P.q.duty;                 % instantaneous secret-key rate [b/s]
    gen = kr*dt;
    ko  = key_scheduler(gen,env.keydem,P,sc.ksched);
    kdelay = ko.delay;                           % s
    m.key_gen_bps   = sum(gen)/T;
    m.key_zero_frac = mean(kr <= 0);
    act = kr > 0;
    if any(act), m.qber = sum(E(act).*kr(act))/sum(kr(act)); else, m.qber = NaN; end
    m.key_dem_bps   = sum(env.keydem)/T;
    m.key_serv_bps  = sum(ko.served)/T;
    m.key_sat       = m.key_serv_bps./max(m.key_dem_bps,1);
    m.key_wait_mean_ms = 1e3*mean(kdelay);
    m.key_wait_p99_ms  = zeros(1,3); m.key_wait_p999_ms = zeros(1,3);
    m.key_p_delayed = zeros(1,3);
    for s = 1:3
        m.key_wait_p99_ms(s)  = 1e3*pct(kdelay(:,s),99);
        m.key_wait_p999_ms(s) = 1e3*pct(kdelay(:,s),99.9);
        m.key_p_delayed(s)    = mean(kdelay(:,s) > 1.5*dt);       % request had to wait for fresh key
    end
    m.key_waste_frac = ko.wasted/max(sum(gen),1);
    m.key_util       = sum(sum(ko.served))/max(sum(gen),1);
    m.mu_mean = NaN;
else
    kr = zeros(N,1); gen = kr; kdelay = zeros(N,3);
    m.key_gen_bps = 0; m.key_zero_frac = 1; m.qber = NaN;
    m.key_dem_bps = sum(env.keydem)/T; m.key_serv_bps = zeros(1,3); m.key_sat = zeros(1,3);
    m.key_wait_mean_ms = zeros(1,3); m.key_wait_p99_ms = zeros(1,3); m.key_wait_p999_ms = zeros(1,3);
    m.key_p_delayed = zeros(1,3); m.key_waste_frac = 0; m.key_util = 0; m.mu_mean = NaN;
end
if keys_only, return; end

% ======================= classical FSO link =======================
Q10 = env.Qbar*env.Ic;                            % Q-factor at the 10 Gb/s reference noise bandwidth
if sc.amc
    rates = P.c.rates; d = P.c.csi_delay;
    Iest = [env.Ic(1)*ones(d,1); env.Ic(1:end-d)];       % delayed channel-state feedback
    Qest = env.Qbar*Iest;
    rs = rates(1)*ones(N,1);
    for k = 2:numel(rates)
        rs(Qest*sqrt(1e10/rates(k)) >= P.c.Q_sel) = rates(k);
    end
else
    rs = P.c.rate_fix*ones(N,1);
end
Qr  = Q10.*sqrt(1e10./rs);
ber = ook_ber(Qr);
fer = zeros(N,1); bad = ber > P.c.ber_fec;
fer(bad) = 1 - (1-ber(bad)).^P.c.frame_bits;
good = rs.*(1-fer);                               % link goodput [b/s]
cap  = max(good*dt - P.q.kappa*gen, 0);           % QKD post-processing traffic is served first
co   = class_scheduler(cap,env.arr,P,sc.csched);

m.link_good_mean = mean(good);  m.link_good_std = std(good);
m.link_good_cov  = std(good)/mean(good);  m.link_good_p5 = pct(good,5);
m.link_fer_frac  = mean(fer > 0.5);
m.cap_lt_load    = mean(good < sum(sl.traffic_bps));
m.ber_mean       = mean(ber);
m.rate_mean      = mean(rs);
m.thr_bps        = sum(co.served)/T;
nw = floor(N/40);                                  % 10 ms windows
tw = reshape(sum(co.served(1:nw*40,:),2),40,nw); tw = sum(tw,1)'/(40*dt);
m.thr_cov10ms    = std(tw)/mean(tw);  m.thr_p5_bps = pct(tw,5);  m.thr_min_bps = min(tw);
ow = reshape(sum(env.arr(1:nw*40,:),2),40,nw); ow = sum(ow,1)'/(40*dt);
m.thr_ratio_p5   = pct(tw./ow,5);                  % 5th percentile of delivered/offered over 10 ms windows
m.offered_bps    = sum(env.arr)/T;
m.loss_ratio     = sum(co.dropped)./sum(env.arr);
% latency
base = sl.base_delay + dt*0;                      % processing + framing (propagation L/c is added below)
prop = P.L/3e8;
e2e  = co.delay + kdelay + base + prop;           % s, N x 3
m.cdelay_p50_ms = zeros(1,3); m.cdelay_p99_ms = zeros(1,3); m.e2e_p99_ms = zeros(1,3);
m.e2e_p999_ms = zeros(1,3);  m.sla = zeros(1,3);
for s = 1:3
    m.cdelay_p50_ms(s) = 1e3*pct(co.delay(:,s),50);
    m.cdelay_p99_ms(s) = 1e3*pct(co.delay(:,s),99);
    m.e2e_p99_ms(s)    = 1e3*pct(e2e(:,s),99);
    m.e2e_p999_ms(s)   = 1e3*pct(e2e(:,s),99.9);
    ok = (e2e(:,s) <= sl.budget_ms(s)*1e-3) & (co.dropped(:,s) <= 0);
    m.sla(s) = mean(ok);
end
% short time series for plots
n2 = min(N,round(2/dt));
m.ts.t = (0:n2-1)'*dt; m.ts.Iq = env.Iq(1:n2); m.ts.Ic = env.Ic(1:n2);
m.ts.kr = kr(1:n2); m.ts.rs = rs(1:n2); m.ts.good = good(1:n2);
m.ts.kdelay = kdelay(1:n2,:); m.ts.e2e = e2e(1:n2,:);
end
