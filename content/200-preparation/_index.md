---
title: "Preparation"
weight: 2
chapter: false
pre: " <b> 2. </b> "
---

## Preparation

<!-- TODO: Link to previous workshop -->

### AWS CLI

Follow previous workshop to install and configure AWS CLI.

Or using the official guide from AWS:

- [Installing or updating to the latest version of the AWS CLI - AWS Command Line Interface](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

To continue with the workshop, you need to verify that you can run 4 following commands:

- Verify AWS CLI works

  ```bash
  aws --version
  # Output: aws-cli/2.27.28 Python/3.13.3 Linux/6.14.9-300.fc42.x86_64 exe/x86_64.fedora.42
  ```

- Verify AWS CLI is configured with your AWS credentials

  ```bash
  aws sts get-caller-identity
  # Output:
  # {
      # "UserId": "AROA5OWSGDSIZREXGLG2K:thangfcj+devops@gmail.com",
      # "Account": "924932512913",
      # "Arn": "arn:aws:sts::924932512913:assumed-role/AWSReservedSSO_AdministratorAccess_6ce8cc3bd00b0421/thangfcj+devops@gmail.com"
  # }
  ```

### jq

jq is a command-line tool for processing JSON data.

- jq will help you to have a better experience when working with AWS CLI output.

  For example, let's say you want to get the `Code.Location` from the output of `aws lambda get-function`:

  ```bash
  aws lambda get-function --function-name myfunction | jq --raw-output .Code.Location
  ```

- Follow the [official guide](https://jqlang.org/download/) to install jq.
