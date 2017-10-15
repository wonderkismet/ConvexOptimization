clear;
close all;
fclose all;

%% prepare data
randn('seed', 1);
beta = zeros(10, 1);
beta(3) = 1;
beta(5) = 7;
beta(10) = 3;
n = 100;
p = 10;
X = randn(n, p);
y = X * beta + 0.1 * randn(n, 1);
lambda = 0.2;

%% solve using fminunc (to verify our result)
a0 = rand(10, 1);
V = @(a) norm(y - X * a, 2) ^ 2 + lambda * norm(a, 1);
aopt = fminunc(V, a0);

%% implement my own algorithm
% beta_pcg = l1_norm_ls_solver_pcg(X, y, lambda);
beta = l1_norm_ls_solver(X, y, lambda);

