function drawAffine(afnv, tsize, color, linewidth)

rect= round(aff2image(afnv', tsize));
inp	= reshape(rect,2,4);

topleft_r = inp(1,1);
topleft_c = inp(2,1);
botleft_r = inp(1,2);
botleft_c = inp(2,2);
topright_r = inp(1,3);
topright_c = inp(2,3);
botright_r = inp(1,4);
botright_c = inp(2,4);
p = line([topleft_c, topright_c], [topleft_r, topright_r]);
set(p, 'Color', color); set(p, 'LineWidth', linewidth); set(p, 'LineStyle', '-');
p = line([topright_c, botright_c], [topright_r, botright_r]);
set(p, 'Color', color); set(p, 'LineWidth', linewidth); set(p, 'LineStyle', '-');
p = line([botright_c, botleft_c], [botright_r, botleft_r]);
set(p, 'Color', color); set(p, 'LineWidth', linewidth); set(p, 'LineStyle', '-');
p = line([botleft_c, topleft_c], [botleft_r, topleft_r]);
set(p, 'Color', color); set(p, 'LineWidth', linewidth); set(p, 'LineStyle', '-');
