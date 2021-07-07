import json
import os

import pandas as pd

from utils import DATASETS, call_bash, get_data_dir, get_params


SEEN_EVERY = 2


class VideoDownloader():
    def __init__(self, gen_dict=None):
        if gen_dict is not None:
            self.params = gen_dict['params']
            self.retriever = 'streamer'
            self.gen_call = True
            self.use_records = self.params['use_records']
            dataset_dir = gen_dict['dataset_dir']
        else:
            self.params = get_params('Ingestion')
            self.retriever = self.params['retriever']
            self.gen_call = False
            self.use_records = False
            dataset_dir = get_data_dir(self.params['dataset'])

        if self.params['toy_set']:
            self.data_dir = dataset_dir + 'data/toy/'
            self.logs_dir = dataset_dir + 'logs/toy/'
            self.tfds_dir = dataset_dir + 'tfds/toy/'
            self.records_dir = dataset_dir + 'records/toy/'
            self.vid_dir = (
                self.params['vid_dir'] + self.params['dataset'] + '/toy/'
            )
        else:
            self.data_dir = dataset_dir + 'data/full/'
            self.logs_dir = dataset_dir + 'logs/full/'
            self.tfds_dir = dataset_dir + 'tfds/full/'
            self.records_dir = dataset_dir + 'records/full/'
            self.vid_dir = (
                self.params['vid_dir'] + self.params['dataset'] + '/full/'
            )

        self.script_dir = (
            os.path.dirname(os.path.realpath(__file__)) + '/scripts/'
        )

    def get_data(self):
        print('Downloading data files...')
        if self.params['dataset'] == 'sports1m':
            data_url = DATASETS[self.params['dataset']]['data']
            labels_url = DATASETS[self.params['dataset']]['labels']
        else:
            data_url = DATASETS[self.params['dataset']]
            labels_url = 'none'
        status = call_bash(
            command = (
                f"'{self.script_dir + 'data.sh'}' "
                f"-g {self.gen_call} "
                f"-r {self.use_records} "
                f"-D '{self.data_dir}' "
                f"-L '{self.logs_dir}' "
                f"-T '{self.tfds_dir}' "
                f"-R '{self.records_dir}' "
                f"-u {data_url} " 
                f"-l {labels_url} "
                f"-d {self.params['dataset']} "
            ),
            message='Data files downloaded.\n',
        )
        if status:
            for s in status.decode('utf-8').split("\n"):
                print(s)

    def setup(self):
        print('Running setup script...')
        if 'actnet' in self.params['dataset']:
            self._create_actnet_csv()
        elif self.params['dataset'] == 'sports1m':
            self._create_sports1m_csv()
        status = call_bash(
            command=(
                f"'{self.script_dir + 'setup.sh'}' "
                f"-D '{self.data_dir}' "
                f"-L '{self.logs_dir}' "
                f"-V '{self.vid_dir}' "
                f"-d {self.params['dataset']} "
                f"-t {self.params['toy_set']} " 
                f"-n {self.params['toy_samples']} "
                f"-i {self.params['time_interval']} "
            ),
            message='Setup complete.\n',
        )
        if status:
            for s in status.decode('utf-8').split("\n"):
                print(s)

    def get_videos(self, split):
        num_ts_cols = self.params['download_fps'] * self.params['time_interval']
        status = call_bash(
            command = (
                f"'{self.script_dir + 'videos.sh'}' "
                f"-g {self.gen_call} "
                f"-R {self.retriever} "
                f"-D '{self.data_dir}' "
                f"-L '{self.logs_dir}' "
                f"-V '{self.vid_dir}' "
                f"-s {split} "
                f"-f {num_ts_cols + 1} "
                f"-x '{self.params['cookies']}' "
                f"-r {self.params['download_fps']} " 
                f"-e {self.params['shorter_edge']} " 
                f"-d {self.params['dataset']} "
                f"-C {self.params['conda_path']} " 
                f"-c {self.params['conda_env']} " 
                f"-B {self.params['download_batch']} " 
                f"-j {self.params['num_jobs']} " 
                f"-u {self.params['use_sampler']} "
                f"-m {self.params['max_duration']} "
                f"-n {self.params['num_samples']} "
                f"-a {self.params['sampling']} "
                f"-t {self.params['sample_duration']} "
            ),
        )
        if status:
            for s in status.decode('utf-8').split("\n"):
                print(s)

    def download_videos(self):
        for split in ['train', 'validate']:
            print(f"Downloading '{split}' videos...")  
            csv_file = self.data_dir + split + 'WC.csv'          
            total = call_bash(
                command=f"wc -l < {csv_file}"
            )
            total = int(total.decode('utf-8').strip("\n"))
            i=0
            while os.path.isfile(csv_file):
                self.get_videos(split)
                 
                i += 1
                seen = self.params['download_batch'] * i
                if seen % SEEN_EVERY == 0 and seen <= total: 
                    print(f"{seen}/{total}")

    def _create_actnet_csv(self):
        data_file = self.data_dir + self.params['dataset']
        with open(data_file + '.json', 'r') as f:
            data_dict = json.load(f)

        data_ls = []
        for k, v in data_dict['database'].items():
            if v['subset'] == 'training':
                split = 'train'
            elif v['subset'] == 'validation':
                split = 'validate'
            elif v['subset'] == 'testing':
                continue
            
            for item in v['annotations']:
                data_ls.append({
                    'label':item['label'],
                    'youtube_id':k,
                    'start_time':int(item['segment'][0]),
                    'duration':int(item['segment'][1] - item['segment'][0]),
                    'split':split,
                })
        df = pd.DataFrame(data_ls)
        df.to_csv(data_file + ".csv",index=False)

    def _create_sports1m_csv(self):
        labels_file = self.data_dir + 'labels.txt'
        with open(labels_file, 'r') as f:
            labels_ls = f.read().splitlines()
        labels_df = pd.DataFrame(
            labels_ls, columns=['label']
        )

        for split in ['train', 'validate']:
            data_file = self.data_dir + split + '.json'
            with open(data_file, 'r') as f:
                data_dict = json.load(f)
            data_df = pd.DataFrame(data_dict)
            data_df = data_df.drop(
                columns=['stitle', 'thumbnail', 'width', 'height'],
            )
            data_df = data_df.rename(
                columns={
                    'label487':'label',
                    'id':'youtube_id',
                    'source487':'split',
                }
            )
            data_df['start_time'] = 0
            data_df = data_df[
                ['label', 'youtube_id', 'start_time', 'duration', 'split']
            ]
            if not self.params['max_duration'] < 0:
                data_df['duration'] = self.params['max_duration']
            data_df.loc[:,'link'] = data_df['label'].map(lambda x: x[0])
            data_df = data_df.explode('label')
            data_df['label'] = data_df['label'].map(
                labels_df['label']
            )
            data_df['link'] = data_df['link'].map(
                labels_df['label']
            )

            data_df.to_csv(
                self.data_dir + split + '.csv',
                index=False,
            )
            







        





