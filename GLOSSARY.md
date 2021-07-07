# Glossary

## Main

* **vid_dir**: Absolute path to where video files are stored to. \
Note: do not set path to within the project's 'data' directory.

* **dataset**: Video set and accompanying data files which the user wishes to download. \
Supported datasets include: kinetics400, kinetics600, kinetics700, kinetics700_2020, HACS, actnet100, actnet200, and sports1M.

## Download

* **cookies**: Absolute path to cookies file, which will be passed to youtube-dl during downloading. \
Passing a cookies file is necessary since many websites will require you to login to authenticate yourself. In order to do so, please install the extension, [Get cookies.txt](https://chrome.google.com/webstore/detail/get-cookiestxt/bgaddhkoddajcdgocldbbfleckgcbcid?hl=en). After that, simply go to the website you wish to download videos from, login, click on the extension, and 'export'. The cookies file should be found in your 'Downloads' directory.\
Note: do not set path to within the project's 'data' or 'results' directories.

* **conda_path**: Absolute path to conda package (if running a conda virtual envionment). This is optional as some users may wish to use Pipenv or no virtual environment at all (not recommended). \
The reason this is a parameter is because the bash scripts do not recognize when a conda environment has been activated, and hence the scripts will fail. So we must manually pass the package directory to the scripts.

* **conda_env**: Name of your Conda virtual environment. This is optional as some users may wish to use Pipenv or no virtual environment at all (not recommended). \
The reason this is a parameter is because the bash scripts do not recognize when a conda environment has been activated, and hence the scripts will fail. So we must manually pass the environment's name to the scripts.

* **retriever**: This refers to the downloading technique to use. \
Supported retrievers include: 'loader' and 'streamer'. \
The Loader will download the full unedited video directly from the website. \
The Streamer will instead only download a special link from the website. This link will allow the Streamer to directly traverse the video and download only the desired portion of that video (while simultaneously editing it as well).

* **num_jobs**: The number of simultaneous (using GNU Parallel) videos to download. A good value to use is one equal to the total number of CPU cores on your machine. 

* **toy_set**: Set to True if user wishes to work a smaller subset to experiment with. \
Note: this is for experimentation only, as any results gathered from this toy set will not be accurate.

* **toy_samples**: Total number of videos to subset for the toy dataset.

* **download_batch**: Batch size of total videos to download on each iteration. This batch size will be evenly distributed to all the workers (i.e. num_jobs). \
Note: Do not set this value too high since HTTP Errors may occur that will terminate the downloading loop. At that point, all videos that were successfully download with that batch will be discarded in favor or rerunning that iteration.

* **download_fps**: This is the frame rate at which FFMPEG will download each video at.

* **time_interval**: Fixed time length (starting from a defined start time) that all videos in the set will be downloaded at (in seconds).

* **shorter_edge**: The maximum length of a frame's shorter side that FFMPEG will download all videos at.

* **use_sampler**: Set to True if user wishes to sample only a portion of the video right away. \
Some datasets do not come with predefined stating points. For these cases, the sampler will auto generate the starting points for you.

* **max_duration**: This is the max length (in seconds) of all the combined samples belonging to a single video. \
Example: If we wish to collect 10 samples from a single video and set max_duration to 30 seconds, then each sample will be 3 seconds long. \
Note: If the video is shorter than the max_duration, this param will be ignored.

* **num_samples**: Total number of samples to collect from each video.

* **sampling**: Sampling tecnique to use. Can be one of 'random' or 'uniform' sampling.

* **sample_duration**: Duration of each sampled clip. While max_duration will limit the combined times of all samples, sample_duration will futher limit the total duration of a single sample. \
Example (following example from max_duration): with each sample currently sitting at 3 seconds long, sample_duration could further trim its value to say 1 second. \
The reason for both these params is that max_duration is more of a grouping of time intervals, while sample_duration hones in on a specific value at each grouping.
