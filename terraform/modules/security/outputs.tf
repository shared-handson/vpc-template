######################################################################
# キーペア関連
######################################################################
output "key_pairs" {
  description = "EC2 Key Pairs"
  value = {
    bastion = {
      key_name = aws_key_pair.bastion.key_name
      payload  = tls_private_key.bastion.private_key_openssh
    },
    workload = {
      key_name = aws_key_pair.workload.key_name
      payload  = tls_private_key.workload.private_key_openssh
    }
  }
  sensitive = true
}


######################################################################
# セキュリティグループ関連
######################################################################
output "bastion_security_group_id" {
  description = "ID of the bastion security group"
  value       = aws_security_group.bastion.id
}


######################################################################
# IAM関連
######################################################################
output "bastion_instance_profile_name" {
  description = "Name of the bastion instance profile"
  value       = aws_iam_instance_profile.bastion.name
}

