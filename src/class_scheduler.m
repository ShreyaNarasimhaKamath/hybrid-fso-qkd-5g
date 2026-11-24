function out = class_scheduler(cap,arr,P,mode)
%CLASS_SCHEDULER  Slice-aware fluid scheduler for the classical FSO capacity.
%   cap : N x 1 bits the link can deliver per step      arr : N x 3 offered bits per step
%   'static' : fixed 1/3 capacity partition (no multiplexing gain)
%   'fair'   : slice-unaware work-conserving max-min fair sharing (what a plain FSO hop does)
%   'qos'    : URLLC strict priority, remaining capacity split by weighted max-min (eMBB:mMTC = 3:1)
N = numel(cap); sl = P.sl;
q = zeros(1,3); served = zeros(N,3); dropped = zeros(N,3);
for t = 1:N
    q = q + arr(t,:);
    c = cap(t);
    if strcmp(mode,'static')
        s = min(q, c/3*ones(1,3));
    elseif strcmp(mode,'fair')
        s = wfill(c,q,ones(1,3));
    else
        s1 = min(q(1),c);
        s23 = wfill(c - s1, q(2:3), sl.cls_w(2:3));
        s = [s1 s23];
    end
    q = q - s;
    ov = max(0,q - sl.qcap_bits);
    q = q - ov;
    served(t,:) = s; dropped(t,:) = ov;
end
out.served = served; out.dropped = dropped;
acc = arr - dropped;                       % accepted bits (drops are charged to the arrival step)
A = cumsum(acc); D = cumsum(served);
out.delay = zeros(N,3);
for s = 1:3
    out.delay(:,s) = virtual_delay(A(:,s),D(:,s),P.dt);
end
end
