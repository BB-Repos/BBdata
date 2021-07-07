from configparser import ConfigParser, ExtendedInterpolation
import os
import subprocess
import sys


BB_DIR = os.path.dirname(os.path.realpath(__file__)) + '/'
CFG = BB_DIR
MAIN = 'base'
KINETICS = 'https://storage.googleapis.com/deepmind-media/Datasets/'
HACS = 'http://hacs.csail.mit.edu/dataset/'
ACTNET = 'http://ec2-52-25-205-214.us-west-2.compute.amazonaws.com/files/'
SPORTS = {
    'data':'https://cs.stanford.edu/people/karpathy/deepvideo/',
    'labels':(
        'https://github.com/gtoderici/sports-1m-dataset/raw/master/labels.txt'
    ),
}
DATASETS = {
    'kinetics400':KINETICS+'kinetics400.tar.gz',
    'kinetics600':KINETICS+'kinetics600.tar.gz',
    'kinetics700':KINETICS+'kinetics700.tar.gz',
    'kinetics700_2020':KINETICS+'kinetics700_2020.tar.gz',
    'hacs':HACS+'HACS_v1.1.1.zip',
    'actnet100':ACTNET+'activity_net.v1-2.min.json',
    'actnet200':ACTNET+'activity_net.v1-3.min.json',
    'sports1m':{
        'data':SPORTS['data']+'sports1m_json.zip',
        'labels':SPORTS['labels']+'labels.txt',
    }
}
SECTIONS = [
    'Download',
]
REQUIRED = [
    'vid_dir',
    'cookies',
]
TYPES = [
    'string', 
    'integer',  
    'boolean', 
]
DEFAULTS = {
    'base':{
        'string':{
            'vid_dir':'/PATH/TO/VID/DIR',
            'cookies':'/PATH/TO/COOKIES/DIR',
            'dataset':'kinetics400',
            'conda_path':'none',
            'conda_env':'none',
            'retriever':'streamer',
            'sampling':'random',
        },
        'integer':{
            'num_jobs':5,
            'toy_samples':100,
            'download_batch':20,
            'download_fps':30,
            'time_interval':10,
            'shorter_edge':320,
            'max_duration':-1,
            'num_samples':10,
            'sample_duration':1,
        },
        'boolean':{
            'toy_set':False,
            'use_sampler':False,
        },
    },
}
FILTERS = {
    'dataset':[
        'kinetics400',
        'kinetics600',
        'kinetics700',
        'kinetics700_2020',
        'hacs',
        'actnet100',
        'actnet200',
        'sports1m',
    ],
    'retriever':[
        'loader',
        'streamer',
    ],
    'sampling':[
        'random',
        'uniform',
    ],
}


def get_params(*args, cfg=CFG+'config.cfg'):
    config = ConfigParser(
        interpolation=ExtendedInterpolation(),
    )
    config.read(cfg)
    params = {}
    for section in args:
        assert isinstance(section, str), f"'{section}' must be a string"
        if section.capitalize() in SECTIONS:
            for option in config.options(section):
                params[option] = eval(config.get(
                    section, 
                    option,
                ))
        else:
            print((
                f"Section '{section}' was not found in the configuration file."
            ))
            print(f"Available sections: {SECTIONS}")
    return params

def update_config(*args, cfg=CFG+'config.cfg'):
    config = ConfigParser(
        interpolation=ExtendedInterpolation(),
    )
    config.read(cfg)
    for arg in args:
        config.set(
            arg[0], 
            arg[1], 
            arg[2],
        )
    with open(cfg, 'w') as f:
        config.write(f)

def set_media_directory(media_dir):
    assert isinstance(media_dir, str), f"'{media_dir}' must be a string"

    update_config((
        'DEFAULT', 
        REQUIRED[0], 
        '\'' + media_dir.rstrip('/') + '/\'',
    ))

def set_cookies_path(path):
    assert isinstance(path, str), f"'{path}' must be a string"

    update_config((
        SECTIONS[0], 
        REQUIRED[1], 
        '\'' + path.rstrip('/') + '\'',
    ))

def update_params(param_dict, cfg=CFG+'config.cfg'):
    assert isinstance(param_dict, dict), f"'{param_dict}' must be a dictionary"
    assert isinstance(cfg, str), f"'{cfg}' must be a string"

    config = ConfigParser(
        interpolation=ExtendedInterpolation()
    )
    config.read(cfg)

    param_dict = filter_params(param_dict)
    for param, value in param_dict.items():
        if param in config.defaults().keys():
            conditional_update(
                'DEFAULT',
                param,
                value,
                cfg=cfg,
            )
        elif config.has_option(SECTIONS[0], param):
            conditional_update(
                SECTIONS[0],
                param,
                value,
                cfg=cfg,
            )

def filter_params(param_dict):
    param_list = get_param_list()

    for param, value in param_dict.copy().items():
        if param not in param_list:
            print(f"Unknown param: '{param}'")
            param_dict.pop(param)
            continue

        if not type_check(param, value):
            type_message(param, value)
            param_dict.pop(param)
            continue

        if param == 'dataset':
            generic_filter(param_dict, param)       
        elif param == 'retriever':
            generic_filter(param_dict, param)
        elif param == 'sampling':
            generic_filter(param_dict, param)
    return param_dict

def conditional_update(
        section, 
        param,
        value,
        cfg=CFG+'config.cfg',
    ):
    if param in DEFAULTS[MAIN]['string']:
        update_config(
            (section, f'{param}', f"'{value}'"),
            cfg=cfg,
        )
    else:
        update_config(
            (section, f'{param}', f'{value}'),
            cfg=cfg,
        )

def get_param_list():
    param_list = []
    for t in TYPES:
        param_list += [k for k in DEFAULTS[MAIN][t]]
    return param_list

def type_check(
        param, 
        value,
    ):
    if isinstance(value, bool):
        if param in DEFAULTS[MAIN]['boolean']:
            return True       
    elif isinstance(value, int):
        if param in DEFAULTS[MAIN]['integer']:
            return True
    elif isinstance(value, str):
        if param in DEFAULTS[MAIN]['string']:
            return True
    return False

def type_message(param, value):
    if isinstance(value, list):
        list_type = type(
            DEFAULTS[MAIN]['list'][param][0]
            ).__name__
        print((
            f"'{param}' must be of type 'list' containing elements of type "
            f"'{list_type}'"
        ))
        print(f"'{param}' was not updated.\n")
    else:
        param_type = get_type(param)
        print(f"'{param}' must be of type '{param_type}'")
        print(f"'{param}' was not updated.\n")
    
def generic_filter(param_dict, param):
    if param_dict[param] not in FILTERS[param]:
        print(f"Supported '{param}' values include: {FILTERS[param]}.")
        print(f"'{param}' was not updated.\n")
        param_dict.pop(param)  

def get_type(param):
    for k, v in DEFAULTS[MAIN].items():
        if param in v:
            return k

def view_config():
    return get_params(*SECTIONS)

def reset_default_params(defaults=MAIN):
    default_dict = {}
    for k, v in DEFAULTS[defaults].items():
        for nested_k, nested_v in v.items():
            default_dict[nested_k] = nested_v
    update_params(default_dict)

def is_dir(path):
    if os.path.isdir(path):
        pass
    else:
        os.mkdir(path)

def get_data_dir(dataset_name):
    return get_module_dir('data/', dataset_name)

def get_module_dir(module, dataset_name):
    is_dir(BB_DIR + module)
    module_dir = os.path.abspath(os.path.join(
        BB_DIR, 
        module,
        dataset_name,
    ))
    is_dir(module_dir)
    return module_dir + '/'

def call_bash(command, message=None):
    try:
        output = subprocess.check_output(
            command, 
            shell=True, 
            stderr=subprocess.STDOUT,
        )
        if message is not None:
            print(message)
        return output
    except subprocess.CalledProcessError as e:
        print(e.output)
        print("Exiting program...")
        sys.exit()

