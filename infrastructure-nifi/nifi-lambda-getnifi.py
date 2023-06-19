import boto3
import json
import os
from urllib.request import urlopen
import urllib3

def lambda_handler(event, context):
    s3 = boto3.resource('s3')
    http = urllib3.PoolManager()
    urls = {'nifi/downloads/zookeeper.tar.gz': os.environ['ZKURL'], 'nifi/downloads/nifi.zip': os.environ['NIFIURL'], 'nifi/downloads/nifi-toolkit.zip': os.environ['TOOLKITURL'],'nifi/downloads/nifi-registry.zip': os.environ['REGISTRYURL']}

    for key in urls:
        s3_object = list(s3.Bucket(os.environ['BUCKET']).objects.filter(Prefix=key))
        if len(s3_object) > 0 and s3_object[0].key == key:
            print(key + ' exists, skipping.')
        else:
            print(key + ' not found, downloading.')
            with urlopen(urls[key]):
                s3.meta.client.upload_fileobj(
                    http.request('GET', urls[key], preload_content=False),
                    os.environ['BUCKET'],
                    key,
                    ExtraArgs={'ServerSideEncryption':'aws:kms','SSEKMSKeyId':os.environ['KEY']})
            print(key + ' put to s3.')

    return {
        'statusCode': 200,
        'body': json.dumps('Complete')
    }
