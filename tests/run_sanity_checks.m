%RUN_SANITY_CHECKS  Quick self-tests of the physical models and schedulers.   >> run_sanity_checks
here = fileparts(mfilename('fullpath')); addpath(fullfile(here,'..','src'));
P = config_params(); ok = true;
chk = @(name,cond) printf('[%s] %s\n',ifelse_str(cond),name);
function s = ifelse_str(c), if c, s = ' OK '; else, s = 'FAIL'; end, end

% 1) Gamma-Gamma fading: unit mean, variance matches analytic scintillation index
set_seed(1); Ns = 2e5;
[a,b,~,SI] = gg_params(1e-14,P.c.lambda,3000,0);
I = gg_fading(a,b,randn(Ns,1),randn(Ns,1));
c1 = abs(mean(I)-1) < 0.02; c2 = abs(var(I)/mean(I)^2 - SI)/SI < 0.05;
chk('Gamma-Gamma fading has unit mean',c1); chk('Gamma-Gamma scintillation index matches analytic value',c2);
% 2) AR(1) driver is unit-variance with the requested correlation
z = ar1(2e5,P.tau_small,P.dt); rho = corrcoef(z(1:end-1),z(2:end)); 
chk('AR(1) lag-1 correlation = exp(-dt/tau)',abs(rho(1,2)-exp(-P.dt/P.tau_small)) < 0.01);
% 3) Decoy-state key rate: monotone in loss, zero at very high loss, QBER floor = misalignment error
lut = build_qkd_lut(P); eg = logspace(-4,0,50);
[R,E] = lut_eval(lut,eg,true);
chk('Key rate is non-decreasing in transmittance',all(diff(R) >= -1e-12));
chk('Key rate is zero at eta = 1e-4 in daylight',R(1) == 0);
chk('QBER at high transmittance approaches e_d',abs(E(end)-P.q.ed) < 0.003);
chk('Adaptive intensity never worse than fixed intensity',all(lut.Ra >= lut.Rs-1e-12));
% 4) Key scheduler conserves key bits and never serves more than demanded
env = gen_environment(P,2,3,P.L); P.N = numel(env.Iq);
gen = 5e5*P.dt*ones(P.N,1);
for mode = {'equal','qos'}
    ko = key_scheduler(gen,env.keydem,P,mode{1});
    cons = sum(sum(ko.served)) + ko.wasted + 0 <= sum(gen) + sum(P.sl.target_s*P.sl.key_bps) + 1e-6;
    chk(['Key scheduler (' mode{1} '): served <= generated + initial buffer'],cons);
    chk(['Key scheduler (' mode{1} '): served <= demanded'],all(sum(ko.served) <= sum(env.keydem)+1e-6));
end
% 5) Classical scheduler conserves traffic
co = class_scheduler(10e9*P.dt*ones(P.N,1),env.arr,P,'qos');
chk('Classical scheduler never serves more than offered',all(sum(co.served) <= sum(env.arr)+1e-3));
% 6) Link budget sanity: loss grows with distance
[e1] = quantum_budget(P,1000); [e2] = quantum_budget(P,4000);
chk('Quantum channel transmittance falls with distance',e2 < e1);
