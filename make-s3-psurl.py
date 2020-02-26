#!/usr/bin/env python3
# https://aws.amazon.com/premiumsupport/knowledge-center/presigned-url-s3-bucket-expiration/
# Copy their example code, slap an argparse and main on it
# ship it!
#
# Usage:
# make-s3-psurl.py -b my-bucket-name -k /path/to/key/in/bucket.zip
# make-s3-psurl.py -bucket my-bucket-name -key /path/to/key/in/bucket.zip -expiry 86400
#
# Prints the pre-signed URL
# Requires your AWS environment is setup for authentication:
# pip3 install awscli
# aws configure
# (enter your AWS credentials, follow prompts)

import boto3
import argparse
from botocore.client import Config


def presign_url(bucket, key, expiry=604800):
    # Get the service client with sigv4 configured
    s3 = boto3.client('s3', config=Config(signature_version='s3v4'))
    # Generate the URL to get 'key-name' from 'bucket-name'
    # URL expires in 604800 seconds (seven days)
    url = s3.generate_presigned_url(
        ClientMethod='get_object',
        Params={
            'Bucket': bucket,
            'Key': key
        },
        ExpiresIn=expiry,
    )
    return url


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Make a S3 presigned URL for key in bucket.')
    parser.add_argument('-b', '-bucket', dest='s3_bucket', type=str, help='Bucket the key is in', required=True)
    parser.add_argument('-k', '-key', dest='s3_key', type=str, help='Key to create PSU for', required=True)
    parser.add_argument('-t', '-expiry', dest='s3_expiry', type=str, help='Key to create PSU for', required=False)
    args = parser.parse_args()
    s3_url = presign_url(args.s3_bucket, args.s3_key, args.s3_expiry)
    print(s3_url)