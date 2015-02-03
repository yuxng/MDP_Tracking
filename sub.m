function s  = sub(s,I),
% s = sub(s,I)
% Returns a subset of the structure s

if ~isempty(s),
  n = fieldnames(s);
  for i = 1:length(n),
    f = n{i};
    s.(f) = s.(f)(I,:);
  end
end





