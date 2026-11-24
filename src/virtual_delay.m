function d = virtual_delay(A,D,dt)
%VIRTUAL_DELAY  Delay of a bit arriving at step t = time until cumulative service D reaches cumulative arrivals A(t).
%   A,D cumulative bit counts (monotone). Same-step service counts as half a step.
%   Bits still queued at the end of the run are censored (delay lower bound).
N = numel(A); d = zeros(N,1); j = 1;
tol = 1e-9*max(A(end),1) + 1e-6;
for t = 1:N
    if j < t, j = t; end
    while j <= N && D(j) < A(t) - tol
        j = j + 1;
    end
    if j > N
        d(t) = (N - t + 1)*dt;
    else
        d(t) = (j - t + 0.5)*dt;
    end
end
end
