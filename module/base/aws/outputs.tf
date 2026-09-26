output "iam_ec2_rl_arn" {
  depends_on = [aws_iam_role.iam_ec2_rl]
  value = aws_iam_role.iam_ec2_rl.arn
}
output "vpc_net_id" {
  depends_on = [aws_vpc.vpc_net]
  value = aws_vpc.vpc_net.id
}
output "vpc_loadbalancer_sn_1_id" {
  depends_on = [aws_subnet.vpc_loadbalancer_sn_1]
  value = aws_subnet.vpc_loadbalancer_sn_1.id
}
output "vpc_loadbalancer_sn_2_id" {
  depends_on = [aws_subnet.vpc_loadbalancer_sn_2]
  value = aws_subnet.vpc_loadbalancer_sn_2.id
}
output "vpc_pvt_rtt_id" {
  depends_on = [aws_route_table.vpc_pvt_rtt]
  value = aws_route_table.vpc_pvt_rtt.id
}
output "vpc_bastion_sg_id" {
  depends_on = [aws_security_group.vpc_bastion_sg]
  value = aws_security_group.vpc_bastion_sg.id
}
output "vpc_loadbalancer_sg_id" {
  depends_on = [aws_security_group.vpc_loadbalancer_sg]
  value = aws_security_group.vpc_loadbalancer_sg.id
}
output "ec2_rsa_kp_id" {
  depends_on = [aws_key_pair.ec2_rsa_kp]
  value = aws_key_pair.ec2_rsa_kp.id
}
