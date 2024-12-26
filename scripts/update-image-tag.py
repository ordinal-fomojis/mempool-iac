import os
import glob
import yaml

IMAGE = os.environ.get('IMAGE')


def main():
    if IMAGE is None:
        raise ValueError('IMAGE environment variable is required')
    manifests_paths = glob.glob('k8s/bitcoin/*.yaml')
    for manifest_path in manifests_paths:
        with open(manifest_path, 'r') as f:
            manifest = list(yaml.safe_load_all(f))
        for obj in manifest:
            if obj['kind'] != 'StatefulSet':
                continue
            obj['spec']['template']['spec']['containers'][0]['image'] = IMAGE

        with open(manifest_path, 'w') as f:
            yaml.dump_all(manifest, f)


if __name__ == '__main__':
    main()
