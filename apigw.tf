resource "aws_api_gateway_rest_api" "api" {
  name        = "payments"
  description = "API to receive payments payload and store to dynamo db"
  endpoint_configuration {
    types = ["REGIONAL"]
  }

}

# write payloadd to dynamo db from api integration 

resource "aws_iam_role" "api_role" {
  name               = "api_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
resource "aws_iam_role_policy" "api_policy" {
  name   = "api_policy"
  role   = aws_iam_role.api_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "dynamodb:PutItem"
      ],
      "Effect": "Allow",
      "Resource": "${aws_dynamodb_table.dynamo.arn}"
    }
  ]
}
EOF
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  depends_on = [
    aws_api_gateway_integration.integration,
  ]
  triggers = {
    declaration = sha1(file("apigw.tf"))
    vtl1 = sha1(filesha1("clip-hook.vtl"))
  }
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_api_gateway_stage" "stage" {
  depends_on    = [aws_cloudwatch_log_group.log_group]
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "dev"

}
resource "aws_api_gateway_resource" "resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "clip"
}
resource "aws_api_gateway_method" "clip_hook_post" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_settings" "settings" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.stage.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled    = true
    data_trace_enabled = true
    logging_level      = "INFO"
  }
}
resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.clip_hook_post.http_method
  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:us-east-1:dynamodb:action/PutItem"
  credentials             = aws_iam_role.api_role.arn
  request_templates = {
    "application/json" = templatefile("clip-hook.vtl",
      {
        "table_name" = aws_dynamodb_table.dynamo.name
      }
    )
  }
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.clip_hook_post.http_method
  status_code = "200"
}
resource "aws_api_gateway_integration_response" "integration_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.clip_hook_post.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code
  depends_on = [
    aws_api_gateway_integration.integration
  ]
}