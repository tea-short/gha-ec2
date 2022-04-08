locals {
  pat_secret_name = "bootstrap"
  org             = "tea-short"
  repo            = "tf-gha"
}

data "template_cloudinit_config" "gha" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = "package_update: true"
  }

  part {
    content_type = "text/cloud-config"
    content      = "package_upgrade: true"
  }

  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash -xe
      yum update -y
      yum install docker -y
      yum install git -y
      yum install jq -y
      curl -fsSL https://rpm.nodesource.com/setup_17.x | bash -
      yum install -y nodejs
      sudo usermod -a -G docker ec2-user
      sudo systemctl start docker
      sudo systemctl enable docker
      export RUNNER_ALLOW_RUNASROOT=true
      mkdir actions-runner
      cd actions-runner
      curl -O -L https://github.com/actions/runner/releases/download/v2.262.1/actions-runner-linux-x64-2.262.1.tar.gz
      tar xzf ./actions-runner-linux-x64-2.262.1.tar.gz
      PAT=$(aws --region ${data.aws_region.current.name} secretsmanager get-secret-value --secret-id ${local.pat_secret_name} | jq -r '.SecretString' | jq -r '.gh_pat')
      token=$(curl -s -XPOST \
          -H "authorization: token $PAT" \
          https://api.github.com/repos/${local.org}/${local.repo}/actions/runners/registration-token |\
          jq -r .token)
      sudo chown ec2-user -R /actions-runner
      ./config.sh --url https://github.com/${local.org}/${local.repo} --token $token --name "my-runner-$(hostname)" --work _work
      sudo ./svc.sh install
      sudo ./svc.sh start
      sudo chown ec2-user -R /actions-runner
      EOF
  }
}
