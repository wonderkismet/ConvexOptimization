function S = SparseRestoration(Im, kernel, lambda, kappa, type)
%% Image restoration with L1 prior
% The objective function: 
% S^* = argmin ||I*k - B||^2 + lambda |\nabla I|_0 or
% S^* = argmin ||I*k - B||^2 + lambda |\nabla I|_1
% This code is written for ELEC5470 convex optimization project Fall 2017-2018
% @author: Shane Yuan
% @date: Dec 4, 2017
% I write this code basd on Jinshan Pan's open source code. Thanks to
% Jinshan Pan
% 
%% Input:
% @Im: Blurred image
% @kernel: blur kernel
% @lambda: weight for the L1 prior
% @kappa: Update ratio in the ADM
%% Output:
% @S: Latent image
%
% The Code is created based on the method described in the following paper 
%   [1] Jinshan Pan, Zhe Hu, Zhixun Su, and Ming-Hsuan Yang,
%        Deblurring Text Images via L0-Regularized Intensity and Gradient
%        Prior, CVPR, 2014. 
%   [2] Li Xu, Cewu Lu, Yi Xu, and Jiaya Jia. Image smoothing via l0 gradient minimization.
%        ACM Trans. Graph., 30(6):174, 2011.
%
%   Author: Jinshan Pan (sdluran@gmail.com)
%   Date  : 05/18/2014

if ~exist('kappa','var')
    kappa = 2.0;
end
% pad image
H = size(Im,1);    W = size(Im,2);
Im = wrap_boundary_liu(Im, opt_fft_size([H W]+size(kernel)-1));
%
S = Im;
betamax = 1e5;
fx = [1, -1];
fy = [1; -1];
[N,M,D] = size(Im);
sizeI2D = [N,M];
otfFx = psf2otf(fx,sizeI2D);
otfFy = psf2otf(fy,sizeI2D);
%
KER = psf2otf(kernel,sizeI2D);
Den_KER = abs(KER).^2;
%
Denormin2 = abs(otfFx).^2 + abs(otfFy ).^2;
if D>1
    Denormin2 = repmat(Denormin2,[1,1,D]);
    KER = repmat(KER,[1,1,D]);
    Den_KER = repmat(Den_KER,[1,1,D]);
end
Normin1 = conj(KER).*fft2(S);
% 
eps = 0.0001;
beta = 2*lambda;
while beta < betamax
    Denormin = Den_KER + beta * Denormin2;
    h = [diff(S,1,2), S(:,1,:) - S(:,end,:)];
    v = [diff(S,1,1); S(1,:,:) - S(end,:,:)];
    % update g
    if (strcmp(type, 'L0'))
        if D==1
            t = (h.^2+v.^2) < lambda / beta;
        else
            t = sum((h.^2+v.^2),3) < lambda / beta;
            t = repmat(t,[1,1,D]);
        end
        h(t)=0; v(t)=0;
    end
    
    if (strcmp(type, 'L1'))
        rho =  lambda / beta;
        for i = 1:size(h, 1)
            for j = 1:size(h, 2)
                gh1 = (2 * h(i, j) - rho) / 2;
                gh2 = (2 * h(i, j) + rho) / 2;
                if (gh1 > 0) 
                    h(i, j) = gh1;
                else if (gh2 < 0)
                        h(i, j) = gh2;
                    else
                        h(i, j) = 0;
                    end
                end
                gv1 = (2 * v(i, j) - rho) / 2;
                gv2 = (2 * v(i, j) + rho) / 2;
                if (gv1 > 0) 
                    v(i, j) = gv1;
                else if (gv2 < 0)
                        v(i, j) = gv2;
                    else
                        v(i, j) = 0;
                    end
                end
            end
        end
    end
    
    if (strcmp(type, 'L0_IRL1'))
        rho =  lambda/beta;
        for i = 1:size(h, 1)
            for j = 1:size(h, 2)
                gh1 = (2 * h(i, j) - 1 / (abs(h(i, j)) + eps) * rho) / 2;
                gh2 = (2 * h(i, j) + 1 / (abs(h(i, j)) + eps) * rho) / 2;
                if (gh1 > 0) 
                    h(i, j) = gh1;
                else if (gh2 < 0)
                        h(i, j) = gh2;
                    else
                        h(i, j) = 0;
                    end
                end
                gv1 = (2 * v(i, j) - 1 / (abs(v(i, j)) + eps) * rho) / 2;
                gv2 = (2 * v(i, j) + 1 / (abs(v(i, j)) + eps) * rho) / 2;
                if (gv1 > 0) 
                    v(i, j) = gv1;
                else if (gv2 < 0)
                        v(i, j) = gv2;
                    else
                        v(i, j) = 0;
                    end
                end
            end
        end
    end
    
    Normin2 = [h(:,end,:) - h(:, 1,:), -diff(h,1,2)];
    Normin2 = Normin2 + [v(end,:,:) - v(1, :,:); -diff(v,1,1)];
    FS = (Normin1 + beta*fft2(Normin2))./Denormin;
    S = real(ifft2(FS));
    beta = beta*kappa;
end
S = S(1:H, 1:W, :);
end