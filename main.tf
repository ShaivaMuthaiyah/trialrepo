

#Main lambda funciton that will send the email
resource "aws_lambda_function" "send_email_function" {

  function_name = "Send_Email_to_SNS"
  handler = "handler.send_email"
  runtime = "Python3.9"
  role = "${aws_iam_role.lambda_exec.arn}"

  s3_bucket = "${aws_s3_bucket.lambda_codes.arn}"
  s3_key    = "handler.zip"

}

#bucket to upload lambda code into
resource "aws_s3_bucket" "lambda_codes" {
  bucket = "my-tf-test-bucket"
 
}



#Execution role for lambda 
resource "aws_iam_role" "lambda_exec" {
  name = "serverless_example_lambda"

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

#Permission for api gateway to trigger lambda
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.send_email_function.function_name}"
  principal     = "apigateway.amazonaws.com"


  source_arn = "${aws_api_gateway_rest_api.example.execution_arn}/*/*"
}


#api gateway that will be triggered when form is submitted
resource "aws_api_gateway_rest_api" "Form_Response" {
  name        = "email_sns_api"
  description = "Main API endpoint for front-end form"
}


#makes the path for the api
resource "aws_api_gateway_resource" "path_routing" {
  path_part   = "contact-us"
  parent_id   = aws_api_gateway_rest_api.Form_Response.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.Form_Response.id
}

#deploys api 
resource "aws_api_gateway_deployment" "api_gateway_deployment_post" {
  depends_on = [aws_api_gateway_integration.lambda_integration_post]

  rest_api_id = aws_api_gateway_rest_api.Form_Response.id
}


#Production stage for the api 
resource "aws_api_gateway_stage" "prod_stage" {

  stage_name = "prod"
  rest_api_id = aws_api_gateway_rest_api.Form_Response.id
  deployment_id = aws_api_gateway_deployment.api_gateway_deployment_post.id
}


#Method to trigger lambda
resource "aws_api_gateway_method" "Form_Response_post" {
  rest_api_id   = aws_api_gateway_rest_api.Form_Response.id
  resource_id   = aws_api_gateway_resource.path_routing.id
  http_method   = "POST"
  authorization = "NONE"
 
}


#integrating lambda with api gateway with post method
resource "aws_api_gateway_integration" "lambda_integration_post" {
  depends_on = [
    aws_lambda_permission.apigw
  ]
  rest_api_id   = aws_api_gateway_rest_api.Form_Response.id
  resource_id   = aws_api_gateway_resource.path_routing.id

  http_method = "POST"
  integration_http_method = "POST" 
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.send_email_function.invoke_arn
}