data "aws_iam_policy_document" "iam_document" {
  statement {
    actions = var.policy_document_info.actions
    effect  = var.policy_document_info.effect
    principals {
      type        = var.policy_document_info.type
      identifiers = var.policy_document_info.identifiers
    }
  }
}

resource "aws_iam_role" "iam_role" {
  name               = var.iam_role_name
  assume_role_policy = data.aws_iam_policy_document.iam_document.json
}

data "aws_iam_policy" "iam_policy" {
  arn = var.iam_policy_arn
}

resource "aws_iam_role_policy_attachment" "iam_role_policy_attach" {
  role       = aws_iam_role.iam_role.name
  policy_arn = data.aws_iam_policy.iam_policy.arn
}