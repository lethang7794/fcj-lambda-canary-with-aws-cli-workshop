---
title: "Lambda deployment using AWS CLI"
weight: 3
chapter: false
pre: " <b> 3. </b> "
---

Before implementing a Lambda canary deployment with AWS CLI, we will first implement a normal deployment for Lambda using AWS CLI.

When deploying a Lambda function using AWS CLI, there are two scenarios to consider:

1. **Initial Deployment**: When deploying the Lambda function for the first time
2. **Code Update**: When updating the code of an existing Lambda function

Each scenario requires a different AWS CLI command to ensure proper deployment.

{{% toc %}}

### Initial Deployment with AWS CLI

- Create an execution role for the Lambda function

  - Define the trust policy in a file named `trust-policy.json` in your working directory.

    ```json
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": "lambda.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
    ```

  - Run `aws iam create-role` to create an IAM role with previous trust policy:

    ```bash
    aws iam create-role \
        --role-name myfunction-role \
        --assume-role-policy-document file://trust-policy.json
    ```

    Output:

    ```json
    {
      "Role": {
        "Path": "/",
        "RoleName": "myfunction-role",
        "RoleId": "AROA5OWSGDSI2AOEY3JMW",
        "Arn": "arn:aws:iam::924932512913:role/myfunction-role",
        "CreateDate": "2025-06-09T03:03:46+00:00",
        "AssumeRolePolicyDocument": {
          "Version": "2012-10-17",
          "Statement": [
            {
              "Effect": "Allow",
              "Principal": {
                "Service": "lambda.amazonaws.com"
              },
              "Action": "sts:AssumeRole"
            }
          ]
        }
      }
    }
    ```

    > [!NOTE]
    > Copy the ARN of the role (e.g. `arn:aws:iam::924932512913:role/myfunction-role`) for the next step.

  - Attach the basic permissions to invoke a Lambda function - `AWSLambdaBasicExecutionRole` policy - to the role

    ```bash
    aws iam attach-role-policy \
        --role-name myfunction-role \
        --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
    ```

- Create the Lambda function

  ```bash
  aws lambda create-function \
      --function-name myfunction \
      --runtime nodejs22.x \
      --handler index.handler \
      --zip-file fileb://myfunction.zip \
      --role arn:aws:iam::924932512913:role/myfunction-role \
      --timeout 3 \
      --memory-size 128
  ```

  > [!NOTE]
  > Update the `--role` parameter with the ARN of the role you created in the previous step.

- [Optional] Verify that the function is deployed successfully by invoking it.

  ```bash
  $ aws lambda invoke --function-name myfunction --no-cli-pager output.json
  {
      "StatusCode": 200,
      "ExecutedVersion": "$LATEST"
  }

  $ cat output.json
  {"statusCode":200,"body":"\"Hello from Lambda!\""}%
  ```

### Code Update with AWS CLI

- Download `myfunction-v1.zip` from this link, then put it in your working directory.

  <!-- TODO: update link -->

- Update the code in the deployment package

  ```bash
  aws lambda update-function-code \
      --function-name myfunction \
      --zip-file fileb://myfunction-v1.zip
  ```

- Update the configuration of the Lambda function

  ```bash
  aws lambda update-function-configuration \
      --function-name myfunction \
      --timeout 3 \
      --memory-size 256
  ```
