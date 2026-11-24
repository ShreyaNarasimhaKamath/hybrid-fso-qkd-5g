%MAIN  Run the whole study:  >> main
%   Hybrid classical-quantum FSO backhaul with QoS-aware QKD for 5G network slicing.
%   Works in MATLAB (base install, no toolboxes) and GNU Octave >= 6.
clear; clc;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'src'));
outdir = fullfile(here,'results');
P = config_params();
tic; res = run_experiments(P,outdir); printf('Simulation finished in %.0f s\n',toc);
make_figures(P,res,outdir);
print_report(P,res);
