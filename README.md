# Learning to Track: Online Multi-Object Tracking by Decision Making

Created by Yu Xiang at CVGL, Stanford University.

### Introduction

**L2A** is a online multi-object tracking framework based on Markov Decision Processes (MDPs)
The naming stands for "Learning to Associate" when this project started.
Then we moved to learning to track with the same repository.

http://cvgl.stanford.edu/projects/MDP_tracking/

### License

L2A is released under the MIT License (refer to the LICENSE file for details).

### Citation

If you find L2A useful in your research, please consider citing:

    @inproceedings{xiang2015learning,
        Author = {Xiang, Yu and Alahi, Alexandre and Savarese, Silvio},
        Title = {Learning to Track: Online Multi-Object Tracking by Decision Making},
        Booktitle = {International Conference on Computer Vision (ICCV)},
        Year = {2015}
    }

### Usage

1. Download the 2D MOT benchmark from https://motchallenge.net/data/2D_MOT_2015/

2. Set the path of the MOT dataset in global.m

3. For validataion, use MOT_cross_validation.m

4. For testing, use MOT_test.m
