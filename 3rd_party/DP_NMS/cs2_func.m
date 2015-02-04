% This function calls c implementation of push-relabel algorithm. It is downloaded from http://www.igsystems.com/cs2/index.html and then we mex'ed it to run faster in matlab.
% dat_in = [tail head cost lb ub];
% dat_out = [frail fhead flow];
% excess_node = [source_num   sink_num];
% excess_flow = [sourec_flow  sink_flow];

function [cost, dat_out] = cs2_func(dat_in, excess_node, excess_flow)

num_arc = size(dat_in,1);

tail = dat_in(:,1)';
head = dat_in(:,2)';
cost = dat_in(:,3)';

low = dat_in(:,4)';
acap = dat_in(:,5)';

num_node = max([tail head]);
scale = 12;
[cost,ftail,fhead,flow] = cs2mex(scale, num_node, num_arc, excess_node, excess_flow, tail, head, low, acap, cost);

dat_out = [ftail fhead flow];
