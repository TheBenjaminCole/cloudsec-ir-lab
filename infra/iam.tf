#########################
# IAM Role for juice shop
#########################

resource "aws_iam_role" "juice_shop_role" {
  name = "juice_shop_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole",
      Principal = { Service = "ec2.amazonaws.com" },
      Effect    = "Allow"
    }]
  })
}

resource "aws_iam_instance_profile" "juice_shop_profile" {
  name = "juice-shop-profile"
  role = aws_iam_role.juice_shop_role.name
}

resource "aws_iam_role_policy" "juice_shop_policy" {
  name = "juice-shop-s3"
  role = aws_iam_role.juice_shop_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["s3:PutObject", "s3:GetObject"],
      Resource = ["arn:aws:s3:::my-s3-labs-bucket/*"]
    }]
  })
}