    provider "aws" {
    region = "us-east-1"
    }

    resource "aws_instance" "minikube_instance" {
    ami           = "ami-0c2b8ca1dad447f8a"
    instance_type = #t3.medium"

    tags = {
        Name = "Minikube-Kubernetes"
    }

    provisioner "remote-exec" {
        inline = [
        "curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64",
        "chmod +x minikube",
        "sudo mv minikube /usr/local/bin/",
        "minikube start --driver=none"
        ]
    }
    }

    resource "aws_security_group" "k8s_security_group" {
    name_prefix = "k8s-sg"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 30000
        to_port     = 32767
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    }

    resource "aws_network_interface_attachment" "sg_attachment" {
    instance_id          = aws_instance.minikube_instance.id
    network_interface_id = aws_security_group.k8s_security_group.id
    }

    output "instance_public_ip" {
    value = aws_instance.minikube_instance.public_ip
    }

    output "instance_public_dns" {
    value = aws_instance.minikube_instance.public_dns
    }

    resource "kubernetes_horizontal_pod_autoscaler" "hpa_backend" {
    metadata {
        name      = "backend-hpa"
        namespace = "default"
    }

    spec {
        scale_target_ref {
        kind       = "Deployment"
        name       = "techdome-backend"
        api_version = "apps/v1"
        }

        min_replicas = 2
        max_replicas = 10

        metrics {
        type = "Resource"
        resource {
            name = "cpu"
            target {
            type                = "Utilization"
            average_utilization = 50
            }
        }
        }
    }
    }
