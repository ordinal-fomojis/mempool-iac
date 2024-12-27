import os
import yaml

NAME = os.environ.get('NAME')
USERNAME = os.environ.get('USERNAME')
SECRET = os.environ.get('SECRET')
FILE_PATH = os.environ.get('FILE_PATH')


def main():
    if NAME is None or USERNAME is None or SECRET is None or FILE_PATH is None:
        raise ValueError('Missing required env variables')
    manifest = {
        'apiVersion': 'v1',
        'kind': 'Secret',
        'metadata': {
            'name': NAME
        },
        'stringData': {
            'BITCOIN_RPC_USERNAME': USERNAME,
            'BITCOIN_RPC_PASSWORD': SECRET
        }
    }
    with open(FILE_PATH, 'w') as f:
        yaml.dump(manifest, f)


if __name__ == '__main__':
    main()
