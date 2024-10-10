resource "aws_iam_role" "codepipeline_role" {
  name = "${var.resource_name}_codepipeline_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  role = aws_iam_role.codepipeline_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",
          "codebuild:*",
          "codedeploy:*",
          "ec2:*",
          "iam:PassRole"
        ]
        Resource = "*"
      },
    ]
  })
  name = "${var.resource_name}_codepipeline_policy"
}

resource "aws_codepipeline" "cicd_pipeline" {
  role_arn = aws_iam_role.codepipeline_role.arn
  name     = "${var.resource_name}_pipeline"

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.pipeline_bucket.bucket
  }

  stage {
    name = "Source"
    action {
      version  = "2"
      provider = "GitHub"
      owner    = "ThirdParty"
      name     = "Source"
      category = "Source"
      configuration = {
        Repo       = "your-repo-name"
        Owner      = "your-github-username"
        OAuthToken = var.github_token
        Branch     = "main"
      }
      output_artifacts = [
        "source_output",
      ]
    }
  }
  stage {
    name = "gcp"
    action {
      provider = "CodeDeploy"
      owner    = "AWS"
      name     = "aws"
      category = "Deploy"
      version  = "1"  # Add the version here
      configuration = {
        DeploymentGroupName = aws_codedeploy_deployment_group.deployment_group.deployment_group_name
        ApplicationName     = aws_codedeploy_app.application.name
      }
      input_artifacts = [
        "source_output",
      ]
    }
  }
}

resource "aws_s3_bucket" "pipeline_bucket" {
  bucket = "${var.resource_name}-pipeline-bucket"
}

resource "aws_codedeploy_app" "application" {
  name = "${var.resource_name}_codedeploy_app"
}

resource "aws_codedeploy_deployment_group" "deployment_group" {
  service_role_arn      = aws_iam_role.codepipeline_role.arn
  deployment_group_name = "${var.resource_name}_deployment_group"
  app_name              = aws_codedeploy_app.application.name

  ec2_tag_set {
    ec2_tag_filter {
      value = "${var.resource_name}_ec2_instance"
      type  = "KEY_AND_VALUE"
      key   = "Name"
    }
  }
}

resource "aws_instance" "ec2_instance" {
  instance_type = "t2.micro"
  ami           = "ami-0866a3c8686eaeeba"

  tags = {
    Name = "${var.resource_name}_ec2_instance"
  }
}
