

#sender identity for SES
resource "aws_ses_email_identity" "owner_email" {
  email = "ShaivaMuthaiya@gmail.com"
}

#configuration set for SNS
resource "aws_ses_configuration_set" "email_project" {
  name = "Email-Project-Set"
}