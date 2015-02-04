function [c] = APGLASSOup(b,A,para)

%% Object: c = argmin (1/2)\|y-Dx\|_2^2+lambda\|x\|_1+\mu\|x_I\|_2^2 
%%                s.t. x_T >0 
%% input arguments:
%%         b -------  D'*y transformed object vector
%%         A -------  D'*D transformed dictionary
%%         para ------ Lambda: Sparsity Level
%%                     (lambda1: template set; lambda2:trivial template; lambda3:\mu)
%%                     Lip: Lipschitz Constant for F(x)
%%                     Maxit: Maximal Iteration number
%%                     nT: number of templates
%% output arguments:
%%         c ------  output Coefficient vetor

%  Initialization
ColDim = size(A,1);
xPrev = zeros(ColDim,1);
x = zeros(ColDim,1);
tPrev = 1;
t = 1;
lambda = para.Lambda;
Lip = para.Lip;
maxit = para.Maxit;
nT = para.nT;

temp_lambda = zeros(ColDim,1);
temp_lambda(1:nT) = lambda(1);
temp_lambda(end) = lambda(1);  % fixT template



%% main loop
for iter =1:maxit
    tem_t = (tPrev-1)/t;
    tem_y = (1+tem_t)*x - tem_t*xPrev;
    temp_lambda(nT+1:end-1) = lambda(3)*tem_y(nT+1:end-1);
    tem_y = tem_y - (A*tem_y-b+temp_lambda)/Lip; % update residual
    xPrev = x;
    x(1:nT) = max(tem_y(1:nT),0);
    x(end) = max(tem_y(end),0);
    x(nT+1:end-1) = softthres(tem_y(nT+1:end-1),lambda(2)/Lip);
    tPrev = t;
    t = (1+sqrt(1+4*t^2))/2;
end
c = x;

%% soft thresholding operator
function y = softthres(x,lambda)
y = max(x-lambda,0)-max(-x-lambda,0);


    