---
title: "Clean up"
weight: 5
chapter: false
pre: "<b>5. </b>"
---

{{% toc %}}

#### 1. Delete Lambda function `myfunction`:

- You can go to the [Lambda console's Functions section](https://console.aws.amazon.com/lambda/home?#/functions), choose `myfunction`, click `Actions`, choose `Delete`:

  ![alt text](/images/workshop-5/cleanup--lambda--delete.png)

  Type `confirm`, then click `Delete`:

  ![alt text](/images/workshop-5/cleanup--lambda-delete-confirm.png)

- Or use the AWS CLI:

  ```bash
  aws lambda delete-function --function-name myfunction
  ```

#### 2. Delete the IAM execution role:

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
