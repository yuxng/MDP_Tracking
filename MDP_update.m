% update the weights of q function
function MDP = MDP_update(MDP, difference, f)

MDP.weights = MDP.weights + MDP.alpha * difference .* f;

fprintf('difference = %.2f\n', difference);
fprintf('features ');
for i = 1:MDP.fnum
    fprintf('%f ', f(i));
end
fprintf('\n');
fprintf('weights ');
for i = 1:MDP.fnum
    fprintf('%f ', MDP.weights(i));
end
fprintf('\n');