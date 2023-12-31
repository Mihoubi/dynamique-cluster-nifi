data "aws_iam_policy" "tf-nifi-iam-policy-lambda-getnifi-1" {
  arn = "arn:${data.aws_partition.tf-nifi-aws-partition.partition}:iam::aws:policy/AmazonSSMFullAccess"
}

data "aws_iam_policy" "tf-nifi-iam-policy-lambda-getnifi-2" {
  arn = "arn:${data.aws_partition.tf-nifi-aws-partition.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "tf-nifi-iam-policy-lambda-getnifi-3" {
  name        = "${var.name_prefix}-iam-policy-lambda-getnifi-${random_string.tf-nifi-random.result}"
  path        = "/"
  description = "Provides lambda and S3 KMS plus S3 put"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "LambdaCMK",
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": ["${aws_kms_key.tf-nifi-kmscmk-lambda.arn}"]
    },
    {
      "Sid": "S3CMK",
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": ["${aws_kms_key.tf-nifi-kmscmk-s3.arn}"]
    },
    {
      "Sid": "ListObjectsinBucket",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads",
        "s3:ListMultipartUploadParts"
      ],
      "Resource": ["${aws_s3_bucket.tf-nifi-bucket.arn}"]
    },
   {
      "Sid": "AlloS3actions",
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": ["arn:aws:s3:::tools-nifi"]
    },
    {
      "Sid": "PutObjectsinBucketPrefix",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": ["${aws_s3_bucket.tf-nifi-bucket.arn}/nifi/downloads/*"]
    }
  ]
}
EOF
}

resource "aws_iam_role" "tf-nifi-iam-role-lambda-getnifi" {
  name               = "${var.name_prefix}-iam-role-lambda-getnifi-${random_string.tf-nifi-random.result}"
  path               = "/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Action": "sts:AssumeRole",
          "Principal": {
             "Service": "lambda.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
      }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "tf-nifi-iam-attach-lambda-getnifi-1" {
  role       = aws_iam_role.tf-nifi-iam-role-lambda-getnifi.name
  policy_arn = data.aws_iam_policy.tf-nifi-iam-policy-lambda-getnifi-1.arn
}

resource "aws_iam_role_policy_attachment" "tf-nifi-iam-attach-lambda-getnifi-2" {
  role       = aws_iam_role.tf-nifi-iam-role-lambda-getnifi.name
  policy_arn = data.aws_iam_policy.tf-nifi-iam-policy-lambda-getnifi-2.arn
}

resource "aws_iam_role_policy_attachment" "tf-nifi-iam-attach-lambda-getnifi-3" {
  role       = aws_iam_role.tf-nifi-iam-role-lambda-getnifi.name
  policy_arn = aws_iam_policy.tf-nifi-iam-policy-lambda-getnifi-3.arn
}
