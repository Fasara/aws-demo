data "tls_certificate" "github_actions" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github_actions.certificates[0].sha1_fingerprint]
}

resource "aws_iam_role" "github_actions" {
  name = "aws-demo-github-actions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:Fasara/aws-demo:ref:refs/heads/main",
              "repo:Fasara/aws-demo:pull_request"
            ]
          }
        }
      }
    ]
  })

  tags = {
    Project = "aws-demo-project"
  }
}

resource "aws_iam_role_policy" "github_actions_frontend" {
  name = "frontend-deploy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.frontend.arn,
          "${aws_s3_bucket.frontend.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation"
        ]
        Resource = "*"
      }
    ]
  })
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_role_policy" "github_actions_terraform" {
  name = "terraform-apply"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TerraformStateAccess"
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
        Resource = [
          "arn:aws:s3:::aws-demo-project-tfstate",
          "arn:aws:s3:::aws-demo-project-tfstate/*"
        ]
      },
      {
        Sid    = "FrontendBucketManagement"
        Effect = "Allow"
        Action = [
          "s3:CreateBucket", "s3:DeleteBucket", "s3:GetBucketPolicy", "s3:PutBucketPolicy",
          "s3:DeleteBucketPolicy", "s3:GetBucketPublicAccessBlock", "s3:PutBucketPublicAccessBlock",
          "s3:GetBucketTagging", "s3:PutBucketTagging", "s3:GetBucketVersioning",
          "s3:GetBucketAcl", "s3:GetEncryptionConfiguration", "s3:GetBucketLocation", 
          "s3:GetBucketCORS"
        ]
        Resource = aws_s3_bucket.frontend.arn
      },
      {
        Sid    = "CloudFrontManagement"
        Effect = "Allow"
        Action = [
          "cloudfront:CreateDistribution", "cloudfront:GetDistribution", "cloudfront:UpdateDistribution",
          "cloudfront:DeleteDistribution", "cloudfront:TagResource", "cloudfront:ListTagsForResource",
          "cloudfront:CreateOriginAccessControl", "cloudfront:GetOriginAccessControl",
          "cloudfront:UpdateOriginAccessControl", "cloudfront:DeleteOriginAccessControl",
          "cloudfront:CreateInvalidation"
        ]
        Resource = "*" # CloudFront doesn't support resource-level restriction for most of these
      },
      {
        Sid    = "LambdaManagement"
        Effect = "Allow"
        Action = [
          "lambda:CreateFunction", "lambda:GetFunction", "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration", "lambda:DeleteFunction", "lambda:AddPermission",
          "lambda:RemovePermission", "lambda:GetPolicy", "lambda:TagResource", "lambda:ListVersionsByFunction",
          "lambda:GetFunctionCodeSigningConfig"
        ]
        Resource = aws_lambda_function.backend.arn
      },
      {
        Sid      = "ApiGatewayManagement"
        Effect   = "Allow"
        Action   = ["apigateway:GET", "apigateway:POST", "apigateway:PUT", "apigateway:PATCH", "apigateway:DELETE", "apigateway:TagResource"]
        Resource = "*" # apigatewayv2 Create* actions require "*" since the API ID doesn't exist yet
      },
      {
        Sid    = "DynamoDbManagement"
        Effect = "Allow"
        Action = [
          "dynamodb:CreateTable", "dynamodb:DescribeTable", "dynamodb:UpdateTable", "dynamodb:DeleteTable",
          "dynamodb:TagResource", "dynamodb:ListTagsOfResource", "dynamodb:DescribeContinuousBackups",
          "dynamodb:DescribeTimeToLive", "dynamodb:UpdateTimeToLive"
        ]
        Resource = aws_dynamodb_table.todos.arn
      },
      {
        Sid    = "CognitoManagement"
        Effect = "Allow"
        Action = [
          "cognito-idp:CreateUserPool", "cognito-idp:DescribeUserPool", "cognito-idp:UpdateUserPool",
          "cognito-idp:DeleteUserPool", "cognito-idp:CreateUserPoolClient", "cognito-idp:DescribeUserPoolClient",
          "cognito-idp:UpdateUserPoolClient", "cognito-idp:DeleteUserPoolClient", "cognito-idp:TagResource",
          "cognito-idp:GetUserPoolMfaConfig", "cognito-idp:ListTagsForResource"
        ]
        Resource = aws_cognito_user_pool.main.arn
      },
      {
        Sid      = "CloudWatchLogsManagement"
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:DescribeLogGroups", "logs:PutRetentionPolicy", "logs:DeleteLogGroup", "logs:TagResource"]
        Resource = "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/aws-demo-backend*:*"
      },
      {
        Sid      = "CloudWatchAlarmsManagement"
        Effect   = "Allow"
        Action   = ["cloudwatch:PutMetricAlarm", "cloudwatch:DescribeAlarms", "cloudwatch:DeleteAlarms", "cloudwatch:TagResource", "cloudwatch:ListTagsForResource"]
        Resource = "arn:aws:cloudwatch:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:alarm:aws-demo-backend-*"
      },
      {
        Sid    = "IamAppRoleManagement"
        Effect = "Allow"
        Action = [
          "iam:CreateRole", "iam:GetRole", "iam:DeleteRole", "iam:PutRolePolicy", "iam:GetRolePolicy",
          "iam:DeleteRolePolicy", "iam:AttachRolePolicy", "iam:DetachRolePolicy", "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies", "iam:TagRole", "iam:CreatePolicy", "iam:GetPolicy", "iam:GetPolicyVersion",
          "iam:DeletePolicy", "iam:CreatePolicyVersion", "iam:DeletePolicyVersion", "iam:ListPolicyVersions",
          "iam:PassRole"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-demo-lambda-role",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/aws-demo-lambda-dynamodb-policy"
        ]
      },
      {
        Sid    = "IamOidcAndGithubActionsRoleManagement"
        Effect = "Allow"
        Action = [
          "iam:GetOpenIDConnectProvider", "iam:CreateOpenIDConnectProvider", "iam:UpdateOpenIDConnectProviderThumbprint",
          "iam:DeleteOpenIDConnectProvider", "iam:TagOpenIDConnectProvider", "iam:ListOpenIDConnectProviderTags",
          "iam:GetRole", "iam:UpdateAssumeRolePolicy", "iam:GetRolePolicy", "iam:PutRolePolicy",
          "iam:DeleteRolePolicy", "iam:ListRolePolicies", "iam:TagRole", "iam:ListAttachedRolePolicies"
        ]
        Resource = [
          aws_iam_openid_connect_provider.github_actions.arn,
          aws_iam_role.github_actions.arn
        ]
      }
    ]
  })
}