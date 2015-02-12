% convert dres data to struct
function stInfo = convert_dres_to_struct(dres, Fgt)

numLines = numel(dres.fr);

% quickly check format
assert(all(dres.fr > 0), 'FORMAT ERROR: Frame numbers must be positive.')
assert(all(dres.id > 0), 'FORMAT ERROR: IDs must be positive.')

% min target height
minHeight = 0;
    
% go through all lines
for l = 1:numLines
    if dres.h(l) < minHeight        
        continue;
    end    
    
    fr = dres.fr(l);   % frame number
    id = dres.id(l);   % target id
    
    % bounding box
    stInfo.W(fr,id) = dres.w(l);
    stInfo.H(fr,id) = dres.h(l);
    stInfo.Xi(fr,id) = dres.x(l) + stInfo.W(fr,id)/2;
    stInfo.Yi(fr,id) = dres.y(l) + stInfo.H(fr,id);    
end

% append empty frames?
if nargin > 1
    F = size(stInfo.W,1);
    % if stateInfo shorter, pad with zeros
    if F < Fgt
        missingFrames = F+1:Fgt;
        stInfo.Xi(missingFrames,:) = 0;
        stInfo.Yi(missingFrames,:) = 0;
        stInfo.W(missingFrames,:) = 0;
        stInfo.H(missingFrames,:) = 0;
    end
end

% remove empty target IDs
nzc = ~~sum(stInfo.Xi, 1);

if isfield(stInfo, 'X')
    stInfo.X = stInfo.X(:,nzc);
    stInfo.Y = stInfo.Y(:,nzc);
end

% nzc
% stInfo.Xgp'
if isfield(stInfo,'Xgp')
    stInfo.Xgp = stInfo.Xgp(:,nzc);
    stInfo.Ygp = stInfo.Ygp(:,nzc); 
end

if isfield(stInfo,'Xi')
    stInfo.Xi = stInfo.Xi(:,nzc);
    stInfo.Yi = stInfo.Yi(:,nzc); 
    stInfo.W = stInfo.W(:,nzc);
    stInfo.H = stInfo.H(:,nzc);
end