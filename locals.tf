locals {

  application = "gha-ec2"
  env         = terraform.workspace == "default" ? "dev" : terraform.workspace

  region = data.aws_region.current.name

  gha_user_name = "gha"

  cidr = {
    dev = {
      vpc     = "10.0.0.0/21"
      private = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
      public  = ["10.0.3.0/24", "10.0.4.0/24", "10.0.5.0/24"]
    }
  }

  gha_config = {
    dev = {
      instance_type = "t2.small"
      image_id      = ""
    }
  }

  tags = {
    application = local.application
    environment = local.env
  }
}
