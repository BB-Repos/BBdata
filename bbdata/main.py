import argparse

from download.download import VideoDownloader
from utils import (
    reset_default_params, 
    set_cookies_path,
    set_media_directory, 
    update_params,
)


def str_to_bool(v):
    if isinstance(v, bool):
       return v
    elif v.lower() in ['true', 't', '1']:
        return True
    elif v.lower() in ['false', 'f', '0']:
        return False
    else:
        raise argparse.ArgumentTypeError('Boolean value expected.')

def main():
    parser = argparse.ArgumentParser(
        description="video dataset downloader",
    )
    subparsers = parser.add_subparsers(
        dest='subparser_name', 
        help='sub-command help',
    )

    update_parser = subparsers.add_parser(
        'update', 
        help="updates the downloader parameters",
    )
    update_parser.add_argument(
        '--vid_dir', type=str, default='/PATH/TO/VID/DIR', 
        help="directory where videos will be downloaded to",
    )
    update_parser.add_argument(
        '--dataset', type=str, default='kinetics400',
        help=(
            "one of 'kinetics400', 'kinetics600', 'kinetics700', "
            "'kinetics700_2020, 'HACS', 'actnet100', 'actnet200', or 'sports1M'"
        ),
    )
    update_parser.add_argument(
        '--cookies', type=str, default='/PATH/TO/COOKIES/DIR', 
        help="cookies to pass to youtube-dl",
    )
    update_parser.add_argument(
        '--conda_path', type=str, default='none',
        help="absolute path to conda package (if running a conda env)",
    )
    update_parser.add_argument(
        '--conda_env', type=str, default='none',
        help="name of your environment (if running a conda env)",
    )
    update_parser.add_argument(
        '--retriever', type=str, default='streamer',
        help="one of 'loader' or 'streamer' (original or processed video)",
    )
    update_parser.add_argument(
        '--num_jobs', type=int, default=5,
        help="number of simultaneous jobs to run with GNU Parallel",
    )
    update_parser.add_argument(
        '--toy_set', type=str_to_bool, default=False,
        help="whether to use a smaller dataset to experiment with or not",
    )
    update_parser.add_argument(
        '--toy_samples', type=int, default=100,
        help="number of samples for toy dataset",
    )
    update_parser.add_argument(
        '--download_batch', type=int, default=20,
        help="batch of videos to download on each iteration",
    )
    update_parser.add_argument(
        '--download_fps', type=int, default=30,
        help="frame rate to download each video with",
    )
    update_parser.add_argument(
        '--time_interval', type=int, default=10,
        help="length of video to be downloaded (in seconds)",
    )
    update_parser.add_argument(
        '--shorter_edge', type=int, default=320,
        help="length of frame's shorter side to download at",
    )
    update_parser.add_argument(
        '--use_sampler', type=str_to_bool, default=False,
        help="whether to use a clip sampler or not",
    )
    update_parser.add_argument(
        '--max_duration', type=int, default=300,
        help="max length of video to sample from",
    )
    update_parser.add_argument(
        '--num_samples', type=int, default=10,
        help="total number of sampled clips",
    )
    update_parser.add_argument(
        '--sampling', type=str, default='random',
        help="one of 'random' or 'uniform' sampling",
    )
    update_parser.add_argument(
        '--sample_duration', type=int, default=1,
        help="duration of each sampled clip",
    )

    reset_parser = subparsers.add_parser(
        'reset',
        help="resets params to default values",
    )
    reset_parser.add_argument(
        '--defaults', type=str, default='base',
        help="set of default params",
    )

    download_parser = subparsers.add_parser(
        'download', 
        help="downloads the video dataset",
    )
    download_parser.add_argument(
        '--setup', action='store_true',
        help="whether to run setup script or not (run only once for full set)",
    )

    args = vars(parser.parse_args())

    
    if args['subparser_name'] == 'reset':
        reset_default_params(args['defaults'])
        print('Params reset to default values.')

    elif args['subparser_name'] == 'update':
        args.pop('subparser_name')
        set_media_directory(args.pop('vid_dir'))
        set_cookies_path(args.pop('cookies'))
        update_params(args)
        print('Update complete.')

    elif args['subparser_name'] == 'download':
        downloader = VideoDownloader()
        if args['setup']:
            downloader.get_data()
            downloader.setup()
        downloader.download_videos()
    
if __name__ == '__main__':
    main()





