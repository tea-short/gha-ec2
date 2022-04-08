data "aws_ssm_parameter" "amazon_linux" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-ebs"
}

resource "aws_autoscaling_group" "gha" {
  name_prefix      = "${local.application}-"
  max_size         = 1
  min_size         = 0
  desired_capacity = 1

  vpc_zone_identifier = module.vpc.private_subnets

  launch_template {
    id      = aws_launch_template.gha.id
    version = aws_launch_template.gha.latest_version
  }

  lifecycle {
    create_before_destroy = true
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 0
    }
  }
}

resource "aws_launch_template" "gha" {
  name_prefix = "${local.application}-"
  #image_id                             = data.aws_ami.amazon_linux.id
  image_id                             = data.aws_ssm_parameter.amazon_linux.value
  instance_type                        = local.gha_config[local.env].instance_type
  instance_initiated_shutdown_behavior = "terminate"

  user_data = data.template_cloudinit_config.gha.rendered

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = true
      encrypted             = true
      volume_type           = "io1"
      iops                  = 2000
      volume_size           = 40
    }
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    no_device   = true
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.gha.arn
  }

  tags = merge(
    local.tags,
    { Name = "gha" }
  )

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.tags, { Name = "gha" })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(local.tags, { Name = "gha" })
  }

  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true
    security_groups             = [aws_security_group.gha.id]
  }

  lifecycle {
    create_before_destroy = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
    http_put_response_hop_limit = 1
  }
}
