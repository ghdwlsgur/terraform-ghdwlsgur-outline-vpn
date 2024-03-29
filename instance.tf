data "template_file" "user_data" {
  template = file("${path.module}/external/payload.sh")
}

resource "aws_instance" "linux" {
  ami                         = var.ec2_ami
  instance_type               = var.instance_type
  availability_zone           = var.availability_zone
  associate_public_ip_address = true
  key_name                    = var.key_name
  user_data                   = data.template_file.user_data.rendered

  vpc_security_group_ids = [
    aws_security_group.govpn_security.id
  ]

  provisioner "local-exec" {
    command = "terraform output -raw ssh_private_key > ~/.ssh/${self.key_name}.pem && chmod 400 ~/.ssh/${self.key_name}.pem"
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "rm -rf ~/.ssh/${self.key_name}.pem"
    working_dir = path.module
    on_failure  = continue
  }

  root_block_device {
    volume_size = var.volume_size
  }

  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /tmp/outline.json ]; do sleep 1; done",
    ]
    connection {
      type        = "ssh"
      user        = "ec2-user"
      host        = self.public_ip
      private_key = var.private_key_openssh
    }
  }

  tags = {
    Name = "govpn-ec2-${var.aws_region}"
  }
}

resource "terraform_data" "create_securitygroup_rules" {
  provisioner "local-exec" {
    command     = "bash create_sg_rules.sh ${var.aws_region} ${aws_instance.linux.public_dns} ${chomp(data.http.myip.response_body)}"
    working_dir = "${path.module}/external/"
  }

  triggers_replace = [
    aws_instance.linux.id
  ]
}

data "external" "outline_vpn_local_path" {
  program = ["bash", "-c",
    <<-EOT
      outline_vpn_path=$(which outline-vpn | sed 's,/bin/,/lib/,')          
      echo -n "{\"path\":\"$outline_vpn_path\"}"
    EOT
  ]
}

resource "terraform_data" "apply" {
  provisioner "local-exec" {
    command     = "bash -c 'while true; do if [ -f outline.json ]; then terraform state pull ${aws_security_group.govpn_security.id} && terraform apply --auto-approve -lock=false; break; fi; sleep 1; done'"
    working_dir = "${data.external.outline_vpn_local_path.result.path}/outline-vpn/terraform.tfstate.d/${var.aws_region}"
  }

  triggers_replace = [
    terraform_data.create_securitygroup_rules.id
  ]
}

data "external" "access_key" {
  program     = ["bash", "get_access_key.sh", "${var.aws_region}"]
  working_dir = "${path.module}/external/"

  depends_on = [
    terraform_data.apply
  ]
}



