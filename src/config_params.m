function P = config_params()
%CONFIG_PARAMS  Central parameter set for the hybrid classical-quantum FSO / 5G-slicing study.
%   All physical, protocol and slicing parameters live here so every experiment is reproducible.

% ---------------- Simulation clock ----------------
P.dt        = 0.25e-3;     % time step [s]
P.T         = 8;           % simulated time per run [s]
P.N         = round(P.T/P.dt);
P.nseeds    = 3;           % Monte-Carlo repetitions (independent fading / traffic realisations)

% ---------------- Link geometry / atmosphere ----------------
P.L         = 3000;        % default backhaul hop length [m]
P.V         = 20e3;        % meteorological visibility [m]  (clear air)
P.turb.names = {'Weak','Moderate','Strong'};
P.turb.Cn2   = [1e-15 1e-14 1e-13];   % refractive-index structure constant [m^-2/3]
P.tau_large  = 10e-3;      % coherence time of large-scale (alpha) irradiance fluctuation [s]
P.tau_small  = 2e-3;       % coherence time of small-scale (beta)  irradiance fluctuation [s]

% ---------------- Quantum channel (decoy-state BB84, 850 nm, Si-SPAD) ----------------
P.q.lambda   = 850e-9;
P.q.rate     = 100e6;      % pulse repetition rate [Hz]
P.q.duty     = 0.9;        % fraction of time actually spent on key generation (sync, beaconing)
P.q.theta    = 150e-6;     % effective full beam divergence incl. pointing jitter [rad]
P.q.a_rx     = 0.10;       % receiver aperture radius [m]
P.q.loss_opt_dB = 3;       % Tx+Rx optics, filters, coupling [dB]
P.q.eta_det  = 0.50;       % detector efficiency
P.q.dark_cps = 500;        % dark count rate [cps]
P.q.t_gate   = 1e-9;       % detection gate [s]
P.q.Nb       = 5e-3;       % sky radiance [W m^-2 sr^-1 nm^-1]  (bright daylight)
P.q.dlam_nm  = 0.1;        % spectral filter bandwidth [nm]
P.q.fov      = 50e-6;      % receiver full field of view [rad]
P.q.ed       = 0.015;      % intrinsic optical misalignment error
P.q.f_ec     = 1.16;       % error-correction inefficiency
P.q.sift     = 0.5;        % basis-sifting factor q (conservative 1/2)
P.q.mu_static = 0.5;       % signal intensity of the non-adaptive baseline
P.q.nu_ratio  = 0.2;       % decoy/signal intensity ratio nu = ratio*mu
P.q.mu_grid   = 0.10:0.025:0.90;   % candidate intensities for the fading-adaptive controller
P.q.kappa     = 2;         % classical post-processing traffic per generated key bit (sifting+EC+PA)

% ---------------- Classical channel (1550 nm IM/DD OOK, PIN receiver) ----------------
P.c.lambda   = 1550e-9;
P.c.Ptx_dBm  = 13;         % average transmit power [dBm]
P.c.theta    = 2e-3;       % full beam divergence [rad]
P.c.a_rx     = 0.10;       % receiver aperture radius [m]
P.c.loss_opt_dB = 3;
P.c.resp     = 0.9;        % PD responsivity [A/W]
P.c.sigma0   = 2e-6;       % rms noise current at 10 Gb/s [A]
P.c.rate_fix = 10e9;       % fixed-rate "traditional" link [b/s]
P.c.rates    = [1.25 2.5 5 10]*1e9;  % AMC rate set [b/s]
P.c.Q_sel    = 4.0;        % Q-factor needed to select a rate (margin over FEC limit)
P.c.ber_fec  = 2e-4;       % pre-FEC BER limit of the hard-decision FEC
P.c.frame_bits = 12000;    % 1500-byte frame
P.c.csi_delay = 2;         % control-loop delay for rate selection [steps]

% ---------------- 5G network slices ----------------
P.sl.names       = {'URLLC','eMBB','mMTC'};
P.sl.traffic_bps = [50e6  3e9  300e6];       % mean offered classical load per slice
P.sl.pkt_bits    = [2048  0    1e6];         % packet / batch size used by the traffic generators
P.sl.qcap_bits   = [2e6   2e8  2e7];         % per-slice queue limit
P.sl.budget_ms   = [1     10   100];         % end-to-end latency budget
P.sl.cls_w       = [Inf   3    1];           % classical scheduler weights (QoS-aware; Inf = strict priority)
P.sl.key_bps     = [100e3 250e3 50e3];       % mean secret-key demand per slice
P.sl.key_chunk   = [256   256   5120];       % key request granularity [bits]
P.sl.key_w       = [4 2 1];                  % key-scheduler priority weights
P.sl.key_assured = [1 0 1];                  % slices whose key refill is served first (eMBB is best-effort and can fall back to longer key lifetimes)
P.sl.buf_s       = 0.5;                      % key buffer capacity [s of mean demand]
P.sl.target_s    = 0.1;                      % key buffer fill target [s of mean demand]
P.sl.load_sigma  = 0.3;                      % eMBB load log-normal modulation
P.sl.load_tau    = 0.1;                      % eMBB load correlation time [s]
P.sl.base_delay  = 50e-6;                    % processing / framing delay [s]
P.sl.key_demand_scale = 1.0;                 % global scale on key demand (used for the sweep)

% ---------------- Scenarios compared ----------------
%  name, use_qkd, adaptive_mu, key_sched, amc, cls_sched
P.schemes(1) = struct('name','Traditional FSO',   'qkd',false,'adapt',false,'ksched','equal','amc',false,'csched','fair');
P.schemes(2) = struct('name','Hybrid (static)',   'qkd',true, 'adapt',false,'ksched','equal','amc',false,'csched','fair');
P.schemes(3) = struct('name','Hybrid QoS-aware',  'qkd',true, 'adapt',true, 'ksched','qos',  'amc',true, 'csched','qos');
end
