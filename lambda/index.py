import json
import boto3
from PIL import Image
import io

s3 = boto3.client('s3')

def lambda_handler(event, context):
    print("Event:", event)

    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']

    # ❌ Bỏ qua file đã resize để tránh loop vô hạn
    if key.startswith("resized-"):
        print(f"Skip already resized file: {key}")
        return {
            'statusCode': 200,
            'body': json.dumps(f"Skipped resized file {key}")
        }

    try:
        # Tải ảnh từ S3
        response = s3.get_object(Bucket=bucket, Key=key)
        image = Image.open(response['Body'])

        # Resize ảnh
        image = image.resize((200, 200))

        # Save vào memory
        buffer = io.BytesIO()
        image.save(buffer, 'JPEG')
        buffer.seek(0)

        # Upload ảnh resized lên S3
        resized_key = f"resized-{key}"
        s3.put_object(
            Bucket=bucket,
            Key=resized_key,
            Body=buffer,
            ContentType='image/jpeg'
        )

        print(f"✅ Resized image saved as {resized_key}")
        return {
            'statusCode': 200,
            'body': json.dumps(f"Resized image saved as {resized_key}")
        }

    except Exception as e:
        print(f"❌ Error processing {key}: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f"Error: {str(e)}")
        }

