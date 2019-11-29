terraform {
  backend "local" {
    path = "/tmp/terraform/workspace/terraform.tfstate"
  }

}

provider "aws" {
    regions = "us-east-1"
    shared_crredentials_file= "home/ubuntu/credentials"
    profile = "terraform"

  }


resource "aws_instance" "backend" {
  ami                    = "ami-04763b3055de4860b"
  instance_type          = "t2.micro"
  }

resource "null_resource" "remote-exec-1" {
    connection {
    user        = "ubuntu"
    type        = "ssh"
    host        = "${aws_instance.backend.public_ip}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install python sshpass -y",
    ]
  }
}

resource "null_resource" "ansible-main" {
provisioner "local-exec" {
  command = <<EOT
        sleep 100;
        > jenkins-ci.ini;
        echo "[jenkins-ci]"| tee -a jenkins-ci.ini;
        export ANSIBLE_HOST_KEY_CHECKING=False;
        echo "${aws_instance.backend.public_ip}" | tee -a jenkins-ci.ini;
        ansible-playbook -e  sshKey=${var.pvt_key} -i jenkins-ci.ini ./ansible/setup-backend.yaml -u ubuntu -v
    EOT
}
}
