output "cloudfront_url" {
  value = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

output "api_gateway_url" {
  value = aws_apigatewayv2_stage.backend.invoke_url
}

output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.main.id
}

output "cognito_client_id" {
  value = aws_cognito_user_pool_client.main.id
}