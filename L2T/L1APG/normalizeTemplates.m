function [A, A_norm] = normalizeTemplates(A)
A_norm = sqrt(sum(A.*A))+1e-14;
A = A./(ones(size(A,1),1)*A_norm);