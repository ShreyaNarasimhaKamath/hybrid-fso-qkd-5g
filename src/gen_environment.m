function env = gen_environment(P,iturb,seed,L)
%GEN_ENVIRONMENT  Draw one realisation of channel fading, slice traffic and key demand.
%   Everything random is generated here, so all schemes can be compared on identical realisations
%   (common random numbers).
set_seed(seed);
N = P.N; dt = P.dt; Cn2 = P.turb.Cn2(iturb);
[aq,bq,sq] = gg_params(Cn2,P.q.lambda,L,2*P.q.a_rx);
[ac,bc,sc] = gg_params(Cn2,P.c.lambda,L,2*P.c.a_rx);
z1 = ar1(N,P.tau_large,dt);  z2 = ar1(N,P.tau_small,dt);
env.Iq = gg_fading(aq,bq,z1,z2);        % irradiance fading, 850 nm quantum channel
env.Ic = gg_fading(ac,bc,z1,z2);        % irradiance fading, 1550 nm classical channel (same path => correlated)
env.rytov_q = sq; env.rytov_c = sc;
[env.eta0,env.Y0,qi] = quantum_budget(P,L,Cn2);
[env.Qbar,ci]        = classical_budget(P,L,Cn2);
env.qinfo = qi; env.cinfo = ci;

% --- slice traffic (bits per step) ---
sl = P.sl;
m  = exp(sl.load_sigma*ar1(N,sl.load_tau,dt) - sl.load_sigma^2/2);       % eMBB load modulation (unit mean)
arr = zeros(N,3);
arr(:,1) = poiss(sl.traffic_bps(1)*dt/sl.pkt_bits(1)*ones(N,1))*sl.pkt_bits(1);       % URLLC small packets
arr(:,2) = sl.traffic_bps(2)*dt*m;                                                    % eMBB fluid
arr(:,3) = poiss(sl.traffic_bps(3)*dt/sl.pkt_bits(3)*ones(N,1))*sl.pkt_bits(3);       % mMTC batches
env.arr = arr;
% --- secret-key demand (bits per step), proportional to traffic activity ---
kd = zeros(N,3);
kd(:,1) = poiss(sl.key_bps(1)*dt/sl.key_chunk(1)*ones(N,1))*sl.key_chunk(1);
kd(:,2) = poiss(sl.key_bps(2)*dt/sl.key_chunk(2)*m)*sl.key_chunk(2);
kd(:,3) = poiss(sl.key_bps(3)*dt/sl.key_chunk(3)*ones(N,1))*sl.key_chunk(3);
env.keydem = kd*sl.key_demand_scale;
end
