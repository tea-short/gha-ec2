data aws_secretsmanager_secret "bootstrap" {
  name = "bootstrap"
}

resource "aws_iam_role" "gha" {
  name               = "gha"
  assume_role_policy = data.aws_iam_policy_document.gha_assume_role.json
}

data "aws_iam_policy_document" "gha_assume_role" {
  statement {
    sid     = "AllowSMAssumeRole"
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "gha" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [data.aws_secretsmanager_secret.bootstrap.arn]
  }
}

resource "aws_iam_policy" "gha" {
  name   = "${local.application}"
  policy = data.aws_iam_policy_document.gha.json
}

resource "aws_iam_role_policy_attachment" "gha" {
  role       = aws_iam_role.gha.name
  policy_arn = aws_iam_policy.gha.arn
}

resource "aws_iam_instance_profile" "gha" {
  name = aws_iam_role.gha.name
  role = aws_iam_role.gha.id
}

resource "aws_iam_role_policy_attachment" "gha_cloudwatch_logging" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.gha.id
}

resource "aws_iam_role_policy_attachment" "gha_web_ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.gha.id
}
