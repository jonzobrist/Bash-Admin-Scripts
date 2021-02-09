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

import boto
import argparse
from botocore.client import Config


def presign_url(bucket, key, expiry, profile, region):
    # Get the service client with sigv4 configured
    #session = boto.Session(profile_name=profile_name)
    session = boto.Session(region_name=region, profile_name=profile)
    s3 = session.client('s3', config=Config(signature_version='s3v4'), region_name=region)
#    s3 = session.client('s3', config=Config())
    #s3 = boto.client('s3', config=Config(signature_version='s3v4'))
    # Generate the URL to get 'key-name' from 'bucket-name'
    # URL expires in expiry seconds (default 86400 seconds or 1 day)
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
    parser.add_argument('-t', '-expiry', dest='s3_expiry', type=str, help='Key to create PSU for', required=False, default=86400)
    parser.add_argument('-p', '-profile', dest='profile', type=str, help='AWS CLI profile to use', required=False, default="default")
    parser.add_argument('-r', '-region', dest='region', type=str, help='AWS Region to use', required=False, default="us-east-1")
    args = parser.parse_args()
    s3_url = presign_url(args.s3_bucket, args.s3_key, args.s3_expiry, args.profile, args.region)
    print(s3_url)
