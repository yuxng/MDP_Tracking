function compile

include = ' -I/usr/local/include/opencv/ -I/usr/local/include/';
lib = ' -lopencv_core -lopencv_highgui -lopencv_imgproc -lopencv_video';
eval(['mex lk.cpp -O' include lib]);

mex distance.cpp 
mex imResampleMex.cpp 
mex warp.cpp

disp('Compilation finished.');