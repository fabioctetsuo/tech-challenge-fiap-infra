resource "aws_secretsmanager_secret" "jwt-secret-key" {
 name = "jwt-secret-key"
 recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "jwt-secret-version" {
 secret_id = aws_secretsmanager_secret.jwt-secret-key.id
 secret_string = jsonencode({
   jwt-key = "b7f54b6d35f7e9e3ac2f09d7a2348b6ff9612e2a27c8b90a78f0e9c5d8ab46c2"
 })
}