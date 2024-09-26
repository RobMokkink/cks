resource "aws_iam_role" "role" {
  name     = "${var.prefix}-${var.app_name}-server"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "role" {
  name     = "${var.prefix}-${var.app_name}-server"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Разрешения для CloudWatch
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "cloudwatch:PutMetricData"
        ],
        Resource = "*"
      },
      # Разрешения для SSM
      {
        Effect = "Allow",
        Action = [
          "ssm:DescribeAssociation",
          "ssm:GetDeployablePatchSnapshotForInstance",
          "ssm:GetDocument",
          "ssm:DescribeDocument",
          "ssm:GetManifest",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:ListAssociations",
          "ssm:ListInstanceAssociations",
          "ssm:PutInventory",
          "ssm:PutComplianceItems",
          "ssm:PutConfigurePackageResult",
          "ssm:UpdateAssociationStatus",
          "ssm:UpdateInstanceAssociationStatus",
          "ssm:UpdateInstanceInformation"
        ],
        Resource = "*"
      },
      # Разрешения для SSM Messages
      {
        Effect = "Allow",
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ],
        Resource = "*"
      },
      # Разрешения для EC2 Messages
      {
        Effect = "Allow",
        Action = [
          "ec2messages:AcknowledgeMessage",
          "ec2messages:DeleteMessage",
          "ec2messages:FailMessage",
          "ec2messages:GetEndpoint",
          "ec2messages:GetMessages",
          "ec2messages:SendReply"
        ],
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_policy_attachment" "role" {
  name       = "${var.prefix}-${var.app_name}-server"
  policy_arn = aws_iam_policy.role.arn
  roles      = [aws_iam_role.role.name]
}


resource "aws_iam_instance_profile" "server" {
  name = "${var.prefix}-${var.app_name}-server"
  role = aws_iam_role.role.name
}


resource "aws_launch_template" "server" {
  name_prefix   = "${var.prefix}-${var.app_name}-server"
  image_id      = var.ami
  instance_type = var.instance_type
  user_data = base64encode(file("template/boot.sh"))
    tags = merge(
        var.tags_common,
        {
        Name = "${var.prefix}-${var.app_name}-server"
        }
    )

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.servers1.id]
    delete_on_termination       = "true"
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      delete_on_termination = "true"
      volume_size           = var.volume_size
      volume_type           = var.volume_type
      encrypted             = false

    }

  }
  tag_specifications {
    resource_type = "instance"
        tags = merge(
        var.tags_common,
        {
        Name = "${var.prefix}-${var.app_name}-server"
        }
    )
  }

  tag_specifications {
    resource_type = "volume"
        tags = merge(
        var.tags_common,
        {
        Name = "${var.prefix}-${var.app_name}-server"
        }
    )
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.server.name
  }

  lifecycle {
    create_before_destroy = true
  }
}
