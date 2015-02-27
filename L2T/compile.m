function compile

disp('Unix');

cd L1APG
mex IMGaffine_c.c
cd ..

cd LK
include = ' -I/usr/local/include/opencv/ -I/usr/local/include/';
lib = ' -lopencv_core -lopencv_highgui -lopencv_imgproc -lopencv_video';
eval(['mex lk.cpp -O' include lib]);
cd ..

disp('Compilation finished.');