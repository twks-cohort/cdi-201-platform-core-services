terraform {
  required_version = "~> 1.2"

  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "twks-cohort"
    workspaces {
      prefix = "cdi-201-platform-eks-core-services-"
    }
  }
}
