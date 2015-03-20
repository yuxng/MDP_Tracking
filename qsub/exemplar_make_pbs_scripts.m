function exemplar_make_pbs_scripts

num = 11;

is_multiple = 0;
if is_multiple
    num_job = 36;
    index = round(linspace(1, num, num_job+1));
else
    num_job = num;
end

for o_i = 1:num_job
    
  fid = fopen(sprintf('run%d.sh', o_i), 'w');

  fprintf(fid, '#!/bin/bash\n');
  fprintf(fid, '#PBS -S /bin/bash\n');
  fprintf(fid, '#PBS -N run_it%d\n', o_i);
  fprintf(fid, '#PBS -l nodes=1:ppn=12\n');
  fprintf(fid, '#PBS -l mem=48gb\n');
  fprintf(fid, '#PBS -l walltime=96:00:00\n');
  fprintf(fid, '#PBS -q cvgl\n');
  fprintf(fid, 'echo "I ran on:"\n');
  fprintf(fid, 'cat $PBS_NODEFILE\n');
  
  fprintf(fid, 'cd /scail/scratch/u/yuxiang/L2A\n');
  if is_multiple
      if o_i == num_job
          s = sprintf('%d:%d', index(o_i), index(o_i+1));
      else
          s = sprintf('%d:%d', index(o_i), index(o_i+1)-1);
      end
  else
      s = num2str(o_i);
  end
  fprintf(fid, ['matlab_r2013b -nodesktop -nosplash -r "grid_search(' s '); exit;"']);
  fclose(fid);
end

fid = fopen('exemplar_qsub.sh', 'w');
fprintf(fid, 'for (( i = 1; i <= %d; i++))\n', num_job);
fprintf(fid, 'do\n');
fprintf(fid, '  /usr/local/bin/qsub run$i.sh\n');
fprintf(fid, '  sleep 5\n');
fprintf(fid, 'done\n');
fclose(fid);