provider "aws" {
    region = "ap-south-1"
}
resource "aws_instance" "terraform-ec2" {
    ami = "ami-0645cf88151eb2007"
    key_name = "Inst1"
    instance_type = "t2.micro"
    security_groups = [aws_security_group.check.id]

tags = {
        Name = "Ec2-terraform"
    }
}

output "ec2_public_ip" {
  value = aws_instance.terraform-ec2.public_ip
}
