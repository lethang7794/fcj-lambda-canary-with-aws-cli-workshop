---
title: "Initial Canary Deployment with AWS CLI"
weight: 1
chapter: false
pre: " <b> 4.1 </b> "
---

Before performing a canary deployment and shift traffic to a new version of your Lambda function, first you need to perform the **initial canary deployment** (all traffic will be routed to the first version).

{{% toc %}}

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
