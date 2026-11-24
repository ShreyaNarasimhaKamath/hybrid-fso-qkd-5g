function out = key_scheduler(gen,dem,P,mode)
%KEY_SCHEDULER  Distribute freshly generated secret key bits to per-slice key buffers and serve key requests.
%   gen  : N x 1 key bits generated per step      dem : N x 3 key bits requested per step
%   mode : 'equal' -> static 1/3 split, surplus wasted when a buffer is full  (QoS-blind)
%          'qos'   -> 3-stage allocation:  (1) key-assured slices (URLLC, mMTC) refill their buffers first, weighted by
%                     priority;  (2) all slices refill towards their fill target by weighted water-filling;
%                     (3) any leftover tops up remaining buffer headroom (work conserving, no key is wasted).
N = numel(gen); sl = P.sl;
mean_dem = sl.key_bps*sl.key_demand_scale;
Bmax = sl.buf_s*mean_dem; tgt = sl.target_s*mean_dem;
B = tgt; Qk = zeros(1,3);                 % buffers start at target
served = zeros(N,3); backlog = zeros(N,3); wasted = 0;
w = sl.key_w;
for t = 1:N
    g = gen(t);
    if strcmp(mode,'equal')
        a = g/3*ones(1,3);
    else
        need = max(0, tgt + Qk - B);               % how far each slice is below its target (incl. pending requests)
        a    = wfill(g,need.*sl.key_assured,w);    % stage 1: key-assured slices
        a    = a + wfill(g - sum(a),need - a,w);   % stage 2: everyone, priority-weighted
        left = g - sum(a);
        if left > 1e-12
            head = max(0, Bmax - B - a);
            a = a + wfill(left,head,ones(1,3));
        end
    end
    B = B + a;
    ov = max(0,B - Bmax); wasted = wasted + sum(ov); B = min(B,Bmax);
    Qk = Qk + dem(t,:);
    s  = min(Qk,B);
    Qk = Qk - s; B = B - s;
    served(t,:) = s; backlog(t,:) = Qk;
end
out.served = served; out.backlog = backlog; out.wasted = wasted;
A = cumsum(dem); D = cumsum(served);
out.delay = zeros(N,3);
for s = 1:3
    out.delay(:,s) = virtual_delay(A(:,s),D(:,s),P.dt);
end
end
