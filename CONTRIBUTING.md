# Contributing

## `data/`

See the [data/CONTRIBUTING.md](./data/CONTRIBUTING.md) guide for more details on contributing to our Meltano project.

## `infrastructure/`

The infrastructure dir contains infrastructure as code (IAC) templates for deploying Meltano onto AWS.
It uses Terraform and Helm to deploy and manage AWS resources.
For full details on how we chose to architect our Meltano stack, check out [this blog post]().

### Setup

This project relies on several tools to lint, format and validate `.tf` files and to generate `README.md` files for each module:

- Terraform, currently version >1.0.5, installable from [here](https://www.terraform.io)
- `tflint`, installable from [here](https://github.com/terraform-linters/tflint).
- Linting, formatting and validation is done automatically using git `pre-commit`, installable from [here](https://pre-commit.com/#install).
- `README.md` generation requires `terraform-docs`, installable from [here](https://github.com/terraform-docs/terraform-docs).

### Generating Docs

Both the `deploy/infrastructure` and `deploy/meltano` directories contain Terraform modules for deploying each respective layer of our stack.
To update each modules `README.md` after making changes, we must run `terraform-docs`. E.g.

```sh
cd deploy/infrastructure
terraform-docs .

cd ../meltano
terraform-docs .
```

This will replace the readme file at `deploy/infrastructure/README.md` and `deploy/meltano/README.md` with any changes made to the module and header docs.
