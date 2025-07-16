---
title: "Lambda canary deployment using AWS CLI"
weight: 4
chapter: false
pre: " <b> 4. </b> "
---

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
