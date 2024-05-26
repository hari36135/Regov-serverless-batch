import boto3

def main() -> None:
    """
    Very basic application that reads data from a hard-coded source bucket, prints what is in there and copies a new file
    to a destination bucket. It's print statements serve as checks whether the output arrives at the CloudFormation logs.
    """

    SOURCE_BUCKET = "regov-hari-devops-source"
    DESTINATION_BUCKET = "regov-hari-devops-destination"

    print("Step One: a message from within the container.")

    # Specify AWS credentials and region
    session = boto3.Session(
        aws_access_key_id='<AWS Access key for s3 access',
        aws_secret_access_key='<AWS secret key for s3 access',
        region_name='ap-south-1'
    )

    # Create S3 resource using the session
    s3 = session.resource("s3")
    source_bucket = s3.Bucket(SOURCE_BUCKET)
    destination_bucket = s3.Bucket(DESTINATION_BUCKET)

    print(f"Step Two: let's look into {SOURCE_BUCKET} and see what is in there.")

    for obj in source_bucket.objects.all():
        key = obj.key
        body = obj.get()['Body'].read()
        print(f"{key} holds {body}.")

    print("Step Three: let's try to copy a file from the source bucket to the destination bucket.")

    for obj in source_bucket.objects.all():
        key = obj.key
        copy_source = {'Bucket': SOURCE_BUCKET, 'Key': key}
        destination_bucket.copy(copy_source, key)

    print("Files have been copied successfully.")

if __name__ == "__main__":
    main()
