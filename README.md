# BB-Data

BB-Data is a data and video downloader. The aim of this codebase is to set up a foundation on which future projects might be able to build upon. Supported datasets include:

  * **kinetics400** [[1]](https://deepmind.com/research/open-source/kinetics)
  * **kinetics600** [[2]](https://deepmind.com/research/open-source/kinetics)
  * **kinetics700** [[3]](https://deepmind.com/research/open-source/kinetics)
  * **kinetics700_2020** [[4]](https://deepmind.com/research/open-source/kinetics)
  * **HACS** [[5]](http://hacs.csail.mit.edu/)
  * **actnet100**
  * **actnet200**
  * **sports1m** [[6]](https://github.com/gtoderici/sports-1m-dataset/blob/wiki/ProjectHome.md)
                                                                                
**Note: This repository has only been tested on Ubuntu 18.04 and Debian (Sid).**

## Installation

  1. Create a directory (i.e. BBdata) to clone bbdata into:
  ```
  git clone https://github.com/bb-repo/bbdata.git PATH/TO/BBdata/
  ```
  2. Create a virtual environment (using Pipenv or Conda for example).

  3. Install the project onto your system:
  ```
  pip install -e /PATH/TO/BBdata
  ```
  4. Using apt, install:         
  ```
  apt install parallel
  apt install ffmpeg
  apt install aria2c
  ```                                                                 
  5. Install dependencies:
  ```
  pip install -r BBdata/bbdata/requirements.txt
  ```
  6. Make scripts executable: 
  ```
  chmod +x BBdata/bbdata/download/scripts/data.sh         
  chmod +x BBdata/bbdata/download/scripts/setup.sh         
  chmod +x BBdata/bbdata/download/scripts/videos.sh         
  ```
    
## Params    

This project is setup around a config file which contains numerous adjustable parameters. Any changes to how the project runs must be done here by updating the params. There are 2 main commands to update the params:
  1. The 'reset' command will reset all params back to their default values:
  ```
  python BBdata/bbdata/main.py reset
  ```      
  2. The 'update' command will update all requested params to new values. For example:                 
  ```
  python BBdata/bbdata/main.py update \
    --version 0 \
    --dataset kinetics400 \
    --vid_dir /home/user/Videos/ \
    --num_jobs 5 \
  ```

**Note: Do not set the paths to 'cookies' or 'vid_dir' within the data directory. Best to place them in directories outside of the project.**

There are many params, some of which are interconnected to one another, and some which have limitations. Please see [Glossary](GLOSSARY.md) for a full breakdown of all these params.

## Download

In order to download the video sets, we can make use of the 'download' command. This command contains one option:
  1. setup: retrieves required data files and prepares the data for downloading.

To setup and start downloading, call:
```
python BBdata/bbdata/main.py download --setup
```

**Note: The 'setup' option will clear everything in the data directory. So, if downloading is interrupted, make sure to ommitt 'setup' before restarting downloading.**
```
python BBdata/bbdata/main.py download
```

## Contribute

Contributions from the community are welcomed.

## License

BB-Data is licensed under MIT.

