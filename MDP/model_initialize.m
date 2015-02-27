function model = model_initialize()

rand('state', 0);
randn('state', 0);

model.f_start = 1;
model.f_end = 2;
model.f_det = 3;
model.f_cover = 4;
model.f_bias = 5;
model.f_overlap = 6;
model.f_distance = 7;
model.f_ratio = 8;
model.f_color = 9;
model.f_recon = 10;

model.fnum = 10;
model.weights = rand(model.fnum, 1);
model.weights(1) = 0;
model.weights(2) = 0;
model.lambda = 0.5;
model.print_weights = @print_weights;

model.MAX_ID = 10000;
model.tlds = cell(model.MAX_ID, 1);

function print_weights(model)

for i = 1:model.fnum
    fprintf('%f ', model.weights(i));
end
fprintf('\n');