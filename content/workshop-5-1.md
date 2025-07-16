# Lambda canary deployments using AWS CLI

## Introduction

### Lambda deployment

#### Function code - deployment package

When you create a Lambda function, you package your _function code_ (and its dependencies) into a _deployment package_.

![alt text](/images/diagrams/workshop-5/lambda--deployment-package.drawio.png)

> [!NOTE]
> Lambda supports two types of deployment packages: container images and `.zip` file archives.
>
> To simplify, we only consider a Lambda function backed by a `.zip` file archive.

#### Updating function code for a Lambda function

##### Using a local machine

![alt text](/images/diagrams/workshop-5/lambda--update-function-code--local-machine.drawio.png)

##### Using Lambda Console Editor

![alt text](/images/diagrams/workshop-5/lambda--update-function-code--lambda-console-editor.drawio.png)

#### Each version is an immutable snapshot of code + configuration

![alt text](/images/diagrams/workshop-5/lambda--version.drawio.png)

> [!NOTE]
> There is always a version named `$LATEST`.
>
> To take a snapshot of the code and the configuration of the `$LATEST` version, you _publish_ new version from the `$LATEST` version.

#### Alias points to a specific version

![alt text](/images/diagrams/workshop-5/lambda--alias.drawio.png)

> [!NOTE]
> An alias can also point to two versions. In that case, it's called a _weighted alias_.

#### Deployment package - Version - Alias

![alt text](/images/diagrams/workshop-5/lambda--deployment-package--version--alias.drawio.png)

#### Lambda deployment in action

![alt text](/images/diagrams/workshop-5/lambda--deployment-in-action.drawio.png)

### Deployment strategies

[Deployment strategies](https://docs.aws.amazon.com/whitepapers/latest/introduction-devops-aws/deployment-strategies.html) define how you want to deliver your software. Organizations follow different deployment strategies based on their business model. Some choose to deliver software that is fully tested, and others might want their users to provide feedback and let their users evaluate under development features (such as Beta releases).

AWS Lambda support 5 deployment strategies[^1]:

[^1]: <https://docs.aws.amazon.com/whitepapers/latest/introduction-devops-aws/deployment-strategies-matrix.html>

- In-place deployment
- Blue-green deployment
- Canary deployment
- Linear deployment
- All-at-once deployment

For more information about characteristics of each deployment strategy, see [AWS Whitepaper | Practicing Continuous Integration and Continuous Delivery on AWS | Deployment methods](https://docs.aws.amazon.com/whitepapers/latest/practicing-continuous-integration-continuous-delivery/deployment-methods.html).

### Canary deployment

Canary deployment means you shift traffic to a new version of your application in small increments, and monitor the application for any issues before shifting all traffic to the new version.

### How a canary deployment works with Lambda

![alt text](/images/diagrams/workshop-5/lambda--how-canary-deployment-work.drawio.png)

- To verify that the new version is healthy, you can use CloudWatch alarms to monitor the [invocation metrics](https://docs.aws.amazon.com/lambda/latest/dg/monitoring-metrics-types.html#invocation-metrics) `Errors`

> [!NOTE]
> For AWS Lambda, the _wait time_ is the time between
>
> - the start of the canary deployment, and
> - the time when the new version is fully weighted (100% traffic is routed to the new version).
>
> Usually, it is one of the following values: 5 min, 10 min, 15 min, 30 min.

> [!TIP]
> AWS Lambda integrates with other AWS services to help you monitor and troubleshoot your Lambda functions.
>
> - Lambda automatically monitors Lambda functions on your behalf and reports metrics through Amazon CloudWatch.
> - To help you monitor your code when it runs, Lambda automatically tracks the number of requests, the invocation duration per request, and the number of requests that result in an error.

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

## Lambda deployment using AWS CLI

> [!IMPORTANT]
> To have a deep understanding of
>
> - how canary deployment works with Lambda
> - when implementing canary deployment for Lambda with AWS CDK, what does AWS CDK do under the hood
>
> this workshop will also implement
>
> - a normal deployment (aka `all-in-once` deployment)
> - a canary deployment
>
> for Lambda using AWS CLI.
>
> You can skip straight to the canary deployment implement for Lambda using CDK.

<!-- TODO: Link to CDK -->

When deploying a Lambda function using AWS CLI, there are two scenarios to consider:

1. **Initial Deployment**: When deploying the Lambda function for the first time
2. **Code Update**: When updating the code of an existing Lambda function

Each scenario requires a different AWS CLI command to ensure proper deployment.

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

## Lambda canary deployment using AWS CLI

> [!IMPORTANT]
> To have a deep understanding of
>
> - how canary deployment with Lambda
> - when implementing canary deployment for Lambda with AWS CDK, what does AWS CDK do under the hood
>
> this workshop will also implement
>
> - a normal deployment (aka `all-in-once` deployment)
> - a canary deployment
>
> for Lambda using AWS CLI.
>
> You can skip straight to the canary deployment implement for Lambda using CDK.

<!-- TODO: Link to CDK -->

See [lambda-canary.md](./lambda-canary.md)

Just as when deploy a Lambda function, there are 2 scenarios when you perform a canary deployment:

1. **Initial Canary Deployment**: When performing a canary deployment for the first time (all traffic will be routed to the only version)
2. **Canary Deployment**: When updating the code of an existing Lambda function (and shift a part of traffic to the new version)

### Initial Canary Deployment with AWS CLI

Before performing a canary deployment and shift traffic to a new version of your Lambda function, first you need to perform the **initial canary deployment** (all traffic will be routed to the only version).

#### Publish a version of Lambda function

```bash
# Publish new version of function
aws lambda publish-version --function-name myfunction
```

```json
{
  "Configuration": {
    "FunctionName": "myfunction",
    "FunctionArn": "arn:aws:lambda:ap-southeast-1:971422684006:function:myfunction:1",
    "Runtime": "nodejs22.x",
    "Role": "arn:aws:iam::971422684006:role/service-role/myfunction-role-3xud5eec",
    "Handler": "index.handler",
    "CodeSize": 295,
    "Description": "",
    "Timeout": 3,
    "MemorySize": 128,
    "LastModified": "2025-06-03T08:44:07.300+0000",
    "CodeSha256": "q8E7Nexf5xxhKT9/d4bGpAYOXJYFAUjJ0UDj8OivK8E=",
    "Version": "1",
    "TracingConfig": {
      "Mode": "PassThrough"
    },
    "RevisionId": "758329b6-1b93-4314-8ac4-5463697d2e5e",
    "State": "Active",
    "LastUpdateStatus": "Successful",
    "PackageType": "Zip",
    "Architectures": ["x86_64"],
    "EphemeralStorage": {
      "Size": 512
    },
    "SnapStart": {
      "ApplyOn": "None",
      "OptimizationStatus": "Off"
    },
    "RuntimeVersionConfig": {
      "RuntimeVersionArn": "arn:aws:lambda:ap-southeast-1::runtime:fd2e05b324f99edd3c6e17800b2535deb79bcce74b7506d595a94870b3d9bd2e"
    },
    "LoggingConfig": {
      "LogFormat": "Text",
      "LogGroup": "/aws/lambda/myfunction"
    }
  },
  "Code": {
    "RepositoryType": "S3",
    "Location": "https://awslambda-ap-se-1-tasks.s3.ap-southeast-1.amazonaws.com/snapshots/971422684006/myfunction-3ef06cfa-3b00-4eb4-a912-4ad620483002"
  }
}
```

Output
![alt text](/images/workshop-5/lambda--publish-version.png)

> [!NOTE]
> Notice:
>
> - `Version` is changed from `$LATEST` to `1`.
> - `FunctionArn` is now `arn:aws:lambda:ap-southeast-1:971422684006:function:myfunction:1`. (The same as previous but with a suffix of `:1`).

#### Create an alias point to the first version

- Create an alias name `myalias` that point to version `1`.

  ```bash
  aws lambda create-alias \
    --function-name myfunction \
    --function-version 1 \
    --name myalias
  ```

  Output

  ```json
  {
    "AliasArn": "arn:aws:lambda:ap-southeast-1:971422684006:function:myfunction:myalias",
    "Name": "myalias",
    "FunctionVersion": "1",
    "Description": "",
    "RevisionId": "85dcdad5-f69f-4cae-bf0b-8cdb5276b8f3"
  }
  ```

- Now you have

  - `myfunction`: The Lambda function (in fact it's the `$LATEST` version)
  - `myfunction:1`: The version `1` of your Lambda function
  - `myfunction:myalias`: The alias that points to the `myfunction:1` version

![alt text](/images/diagrams/workshop-5/lambda--canary--create-alias-to-first-version.drawio.png)

#### [Optional] Invoke function, version, and alias

- Invoke the function `myfunction`:

  ```bash
  aws lambda invoke --function-name myfunction - | cat
  ```

  ![alt text](/images/workshop-5/lambda--invoke-function.png)

- Invoke the version `myfunction:1`:

  ```bash
  aws lambda invoke --function-name myfunction:1 - | cat
  ```

  ![alt text](/images/workshop-5/lambda--invoke-version.png)

- Invoke the alias `myfunction:myalias`:

  ```bash
  aws lambda invoke --function-name myfunction:myalias - | cat
  ```

  ![alt text](/images/workshop-5/lambda--invoke-alias.png)

> [!NOTE]
> Although the responses for all invocations are the same:
>
> - ![alt text](/images/workshop-5/lambda--invoke-response.png)
>
> The `ExecutedVersion` are differences:
>
> - When invoking `myfunction`: `ExecutedVersion` is `$LATEST`.
> - When invoking `myfunction:1`: `ExecutedVersion` is `1`.
> - When invoking `myfunction:myalias`: `ExecutedVersion` is `1` (same version as of `myfunction:1`).

### Canary Deployment with AWS CLI

- After the initial canary deployment, you have:

  - a Lambda function `myfunction` (with an _unpublished_ version `$LATEST`),
  - a version `1` of the Lambda function,
  - an alias `myalias` that points to the version `1` of the Lambda function.

  The traffic to your lambda function looks like this:

![alt text](/images/diagrams/workshop-5/lambda--canary--create-alias-to-first-version.drawio.png)

- To perform a canary deployment and shift traffic to a new version of your Lambda function, first you need
  - the new version of the Lambda function.
  - in fact it's the deployment package of the new version of the Lambda function.

> [!TIP]
> To get a new version of your Lambda function, you can use the Code editor in the Lambda console as in previous workshop. But in this step, we will use the CLI to understand how it can be automated.

#### Creating new deployment package

- In a real world situation, you will have code tracked in a VCS (e.g. git). For this workshop, we will download the deployment package of previous version of your Lambda function from AWS.

  ```bash
  aws lambda get-function --function-name myfunction | jq .Code
  ```

  ![alt text](/images/workshop-5/lambda--get-function.png)

- Open the link a browser or use curl to download the deployment package to your local machine.

  ```bash
  $ curl -O \
      $(aws lambda get-function --function-name myfunction | jq .Code.Location --raw-output)
    % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                   Dload  Upload   Total   Spent    Left  Speed
  100   295  100   295    0     0   2088      0 --:--:-- --:--:-- --:--:--  2092

  $ ls -la
  total 8
  drwxr-xr-x. 1 lqt lqt 112 Jun  4 09:56 .
  drwxr-xr-x. 1 lqt lqt  72 Jun  4 09:52 ..
  -rw-r--r--. 1 lqt lqt 295 Jun  4 09:56 myfunction-3ef06cfa-3b00-4eb4-a912-4ad620483002

  $ unzip myfunction-3ef06cfa-3b00-4eb4-a912-4ad620483002
  Archive:  myfunction-3ef06cfa-3b00-4eb4-a912-4ad620483002
   extracting: index.mjs

  $ ls -la
  total 8
  drwxr-xr-x. 1 lqt lqt 112 Jun  4 09:56 .
  drwxr-xr-x. 1 lqt lqt  72 Jun  4 09:52 ..
  -rw-r--r--. 1 lqt lqt 179 Jun 30  2023 index.mjs
  -rw-r--r--. 1 lqt lqt 295 Jun  4 09:56 myfunction-3ef06cfa-3b00-4eb4-a912-4ad620483002
  ```

  The name of the zip file is in the format `<FunctionName>-<UUID>.zip`

- Unzip the deployment package you just downloaded (`<FunctionName>-<UUID>.zip`), you should have a `index.mjs` file.

- Update the `index.mjs` file, change the response to `Hello from Lambda! v2`

  ![alt text](/images/workshop-5/canary-with-aws-cli--new-function-code.png)

- Rezip the function code to make a deployment package, in this workshop, we'll use `zip` command.

  ```bash
  zip -r myfunction-v2.zip index.mjs
  ```

  Now we have a new deployment package `myfunction-v2.zip` (with the updated code).

  ![alt text](/images/workshop-5/canary-with-aws-cli--new-deployment-package.png)

#### Update the Lambda function `$LATEST` with new deployment package

- Update `$LATEST` version of function with new function code

  ```bash
  # Update $LATEST version of function
  aws lambda update-function-code --function-name myfunction --zip-file fileb://myfunction-v2.zip
  ```

  ![alt text](/images/workshop-5/lambda--LATEST-version.png)

  The architecture of the system now looks like this:

![alt text](/images/diagrams/workshop-5/lambda--canary--update-LASTEST.drawio.png)

#### Publish new version of Lambda function from `$LATEST`

- Publish new version of function `myfunction` (`2`):

  ```bash
  # Publish new version of function
  aws lambda publish-version --function-name myfunction
  ```

  ![alt text](/images/workshop-5/lambda--publish-version-from-LATEST.png)

  The architecture of the system now looks like this:

![alt text](/images/diagrams/workshop-5/lambda--canary--publish-new-version.drawio.png)

#### Shift traffic to new version

- Shift 10% traffic to new version (Version `2`) by updating the alias `myalias` and adding the new version `2` to the `myalias`:

  ```bash
  # Point alias to new version, weighted at 10% (original version at 90% of traffic)
  aws lambda update-alias \
    --function-name myfunction \
    --name myalias \
    --routing-config '{ "AdditionalVersionWeights" : {"2" : 0.10} }'
  ```

  Output:

  ![alt text](/images/workshop-5/lambda--update-weights.png)

  The architecture of the system now looks like this:

![alt text](images/diagrams/workshop-5/lambda--canary--shift-traffic.drawio.png)

- Now, we'll wait for the new version to be healthy.

  - To verify the new version is healthy, you can go to the CloudWatch console and check the metrics for the new version.

    ![alt text](/images/workshop-5/lambda--verify-healthy-with-cloudwatch.png)
    ![alt text](/images/workshop-5/lambda--error-metrics.png)

  - Or use the AWS CLI to get the metrics for the new version using `aws cloudwatch get-metric-statistics`:

    ```bash
    aws cloudwatch get-metric-statistics \
      --namespace AWS/Lambda \
      --metric-name Invocations \
      --dimensions Name=FunctionName,Value=myfunction:2 \
      --statistics Sum \
      --start-time 2025-06-04T03:00:00Z \
      --end-time 2025-06-04T04:00:00Z \
      --period 300
    ```

##### Generate traffic to new version

But first we'll need to generate the traffic to our function.

- Make a `generate-traffic.sh` script to generate traffic to our function

  ```bash
  #!/usr/bin/env bash
  #
  # Generate traffic to Lambda function
  #
  end_time=$(date -d '+5 minutes' +%s)
  ALIAS=myalias
  while [[ $(date +%s) -lt $end_time ]]; do
    echo "Invoking Lambda function at $(date)"
    aws lambda invoke --function-name myfunction:$ALIAS --no-cli-pager output.json
    cat output.json
    echo -e "\n"
    sleep 5
  done
  ```

- Give `generate-traffic.sh` execute permission

  ```bash
  chmod +x generate-traffic.sh
  ```

- Invoke the `generate-traffic.sh` script

  ```bash
  ./generate-traffic.sh
  ```

  ![alt text](/images/workshop-5/lambda--generate-traffic.png)

  As you can see:

  - Most of the time the response is `Hello from Lambda!`.
  - Sometimes the response is `Hello from Lambda! v2`.

    The traffic shift is working as expected.

- But we don't need to invoke the old version, we only want to health check the new version.

- Make a `health-check.sh` script to health check the new version

  ```bash
  #!/usr/bin/env bash
  #
  # Health check new version of Lambda function
  #
  NEW_VERSION=2
  end_time=$(date -d '+5 minutes' +%s)
  while [[ $(date +%s) -lt $end_time ]]; do
    echo "Invoking Lambda function at $(date)"
    aws lambda invoke --function-name myfunction:$NEW_VERSION --no-cli-pager output.json
    cat output.json
    echo -e "\n"
    sleep 5
  done
  ```

- Give `health-check.sh` execute permission

  ```bash
  chmod +x health-check.sh
  ```

- Invoke the `health-check.sh` script

  ```bash
  ./health-check.sh
  ```

  ![alt text](/images/workshop-5/lambda--health-check.png)

- Wait for the wait time to passed (e.g. 5 min), if everything looks good, let's shift all the traffic to the new version.

- Set the primary version on the alias to the new version (version `2`) and reset the additional versions (100% traffic will routed to version `2`)

  ```bash
  aws lambda update-alias --function-name myfunction --name myalias --function-version 2 --routing-config '{}'
  ```

- [Optional] If something goes wrong, you can roll back to the previous version (version `1`) by updating the alias to point to the previous version (version `1`).

  ```bash
  aws lambda update-alias --function-name myfunction --name myalias --function-version 1 --routing-config '{}'
  ```

> [!NOTE]
> For each canary deployment, you need to repeat this whole process, which can be done with a shell script, but the process is error prone.

<!-- TODO: Merge lambda-canary.md -->

## Clean up

- Delete Lambda function `myfunction`:

  - You can go to the [Lambda console's Functions section](https://console.aws.amazon.com/lambda/home?#/functions), choose `myfunction`, click `Actions`, choose `Delete`:

    ![alt text](/images/workshop-5/cleanup--lambda--delete.png)

    Type `confirm`, then click `Delete`:

    ![alt text](/images/workshop-5/cleanup--lambda-delete-confirm.png)

  - Or use the AWS CLI:

    ```bash
    aws lambda delete-function --function-name myfunction
    ```

- Delete the IAM execution role:

  Detach the IAM role policy:

  ```bash
  aws iam detach-role-policy \
          --role-name myfunction-role \
          --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
  ```

  Delete the role

  ```bash
  aws iam delete-role \
        --role-name myfunction-role
  ```
