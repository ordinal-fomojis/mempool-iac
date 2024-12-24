import os
import yaml

IMAGE = os.environ.get('IMAGE', 'not-set')


def main():
    with open('k8s/bitcoin/manifest.yaml', 'r') as f:
        manifest = list(yaml.safe_load_all(f))
    for obj in manifest:
        if obj['kind'] != 'StatefulSet':
            continue
        obj['spec']['template']['spec']['containers'][0]['image'] = IMAGE

    with open('k8s/bitcoin/manifest.yaml', 'w') as f:
        yaml.dump(manifest, f)


if __name__ == '__main__':
    main()
