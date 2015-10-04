# Learning to Track: Online Multi-Object Tracking by Decision Making

Created by Yu Xiang at CVGL, Stanford University.

### Introduction

**MDP_Tracking** is a online multi-object tracking framework based on Markov Decision Processes (MDPs).

http://cvgl.stanford.edu/projects/MDP_tracking/

### License

MDP_Tracking is released under the MIT License (refer to the LICENSE file for details).

### Citation

If you find MDP_Tracking useful in your research, please consider citing:

    @inproceedings{xiang2015learning,
        Author = {Xiang, Yu and Alahi, Alexandre and Savarese, Silvio},
        Title = {Learning to Track: Online Multi-Object Tracking by Decision Making},
        Booktitle = {International Conference on Computer Vision (ICCV)},
        Year = {2015}
    }

### Usage

1. Download the 2D MOT benchmark (data and development kit) from https://motchallenge.net/data/2D_MOT_2015/

2. Set the path of the MOT dataset in global.m

3. Run compile.m

4. For validataion, use MOT_cross_validation.m

5. For testing, use MOT_test.m
