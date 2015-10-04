% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% fix annotation errors in ETH-Bahnhof
function dres_gt = fix_groundtruth(seq_name, dres_gt)

% fix ground truth error
if strcmp(seq_name, 'ETH-Bahnhof') == 1
    index = dres_gt.id == 10 | dres_gt.id == 18 | dres_gt.id == 19 | dres_gt.id == 21;
    dres_gt.id(index) = 4;
    
    index = dres_gt.id == 11;
    dres_gt.id(index) = 1;
    
    index = dres_gt.id == 20 | dres_gt.id == 25 | dres_gt.id == 32;
    dres_gt.id(index) = 12;
    
    index = dres_gt.id == 29;
    dres_gt.id(index) = 27;
    
    index1 = dres_gt.id == 30 & dres_gt.fr >= 247 & dres_gt.fr < 255;
    index2 = dres_gt.id == 31 & dres_gt.fr >= 247 & dres_gt.fr < 255;
    dres_gt.id(index1) = 31;        
    dres_gt.id(index2) = 30;        
    
    index = dres_gt.id == 34;
    dres_gt.id(index) = 30;
    
    index = dres_gt.id == 35;
    dres_gt.id(index) = 31;
    
    index = dres_gt.id == 49;
    dres_gt.id(index) = 43;     
    
    index = dres_gt.id == 51 | dres_gt.id == 53 | dres_gt.id == 56;
    dres_gt.id(index) = 44;
    
    index = dres_gt.id == 60;
    dres_gt.id(index) = 54;
    
    index = dres_gt.id == 59;
    dres_gt.id(index) = 55;    
    
    index = dres_gt.id == 72 | dres_gt.id == 81;
    dres_gt.id(index) = 52;     
    
    index = dres_gt.id == 67 | dres_gt.id == 80;
    dres_gt.id(index) = 62;  
    
    index = dres_gt.id == 68;
    dres_gt.id(index) = 64;      
    
    index = dres_gt.id == 69;
    dres_gt.id(index) = 66;      
    
    index = dres_gt.id == 70 | dres_gt.id == 115;
    dres_gt.id(index) = 46;
    
    index = dres_gt.id == 71;
    dres_gt.id(index) = 45;          
    
    index = dres_gt.id == 74 | dres_gt.id == 77;
    dres_gt.id(index) = 65;   
    
    index = dres_gt.id == 76 | dres_gt.id == 84;
    dres_gt.id(index) = 73;    
    
    index = dres_gt.id == 86;
    dres_gt.id(index) = 82; 
    
    index = dres_gt.id == 87;
    dres_gt.id(index) = 45;        
    
    index = dres_gt.id == 88;
    dres_gt.id(index) = 61;    
    
    index = dres_gt.id == 47 & dres_gt.fr >= 478;
    dres_gt.id(index) = 46;    
    
    index = dres_gt.id == 90;
    dres_gt.id(index) = 47;    
    
    index = dres_gt.id == 79 | dres_gt.id == 91 | dres_gt.id == 98 | dres_gt.id == 99;
    dres_gt.id(index) = 48; 
    
    index = dres_gt.id == 93 | dres_gt.id == 122;
    dres_gt.id(index) = 75; 
    
    index = dres_gt.id == 95;
    dres_gt.id(index) = 89;     
    
    index = dres_gt.id == 78;
    dres_gt.id(index) = 66;      
    
    index = dres_gt.id == 100 | dres_gt.id == 120 | dres_gt.id == 127 | dres_gt.id == 133 | dres_gt.id == 135;
    dres_gt.id(index) = 83;   
    
    index = dres_gt.id == 128;
    dres_gt.id(index) = 73;       
    
    index = dres_gt.id == 129;
    dres_gt.id(index) = 101;        
    
    index = dres_gt.id == 125;
    dres_gt.id(index) = 110;
    
    index = dres_gt.id == 123 | dres_gt.id == 138;
    dres_gt.id(index) = 103;   
    
    index = dres_gt.id == 130;
    dres_gt.id(index) = 108;      
    
    index = dres_gt.id == 132;
    dres_gt.id(index) = 131;   
    
    index = dres_gt.id == 143;
    dres_gt.id(index) = 119;     
    
    index = dres_gt.id == 145 & dres_gt.fr >= 660;
    dres_gt.id(index) = 108;      
    
    index = dres_gt.id == 141 | dres_gt.id == 157;
    dres_gt.id(index) = 121;
    
    index = dres_gt.id == 159;
    dres_gt.id(index) = 158;
    
    index = dres_gt.id == 163 | dres_gt.id == 173;
    dres_gt.id(index) = 152;
    
    index = dres_gt.id == 162 | dres_gt.id == 170;
    dres_gt.id(index) = 153;   
    
    index = dres_gt.id == 160 | dres_gt.id == 172 | (dres_gt.id == 175 & dres_gt.fr >= 738) | dres_gt.id == 181 ...
        | dres_gt.id == 188 | dres_gt.id == 190;
    dres_gt.id(index) = 154;   
    
    index = dres_gt.id == 161 | dres_gt.id == 164 | dres_gt.id == 175;
    dres_gt.id(index) = 156;
    
    index = dres_gt.id == 177 | dres_gt.id == 183 | dres_gt.id == 189;
    dres_gt.id(index) = 171;    
    
    index = dres_gt.id == 178 | dres_gt.id == 184;
    dres_gt.id(index) = 176;    
    
    index = dres_gt.id == 185;
    dres_gt.id(index) = 182; 
    
    index = dres_gt.id == 192;
    dres_gt.id(index) = 186;  
    
    index = dres_gt.id == 202;
    dres_gt.id(index) = 194;   
    
    index = dres_gt.id == 203;
    dres_gt.id(index) = 200;
    
    index = dres_gt.id == 204;
    dres_gt.id(index) = 199;       
    
    index = dres_gt.id == 206;
    dres_gt.id(index) = 198;  
    
    index = dres_gt.id == 207;
    dres_gt.id(index) = 197;       
    
    index = dres_gt.id == 208 | dres_gt.id == 220;
    dres_gt.id(index) = 196;      
    
    index = dres_gt.id == 209 | dres_gt.id == 221;
    dres_gt.id(index) = 195;
    
    index = dres_gt.id == 214;
    dres_gt.id(index) = 210;     
    
    index = dres_gt.id == 217 | dres_gt.id == 222;
    dres_gt.id(index) = 211;  
    
    index = dres_gt.id == 218 | dres_gt.id == 223;
    dres_gt.id(index) = 212;               
end