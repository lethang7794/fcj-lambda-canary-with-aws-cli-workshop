---
title: "Introduction"
weight: 1
chapter: false
pre: " <b> 1. </b> "
---

## Introduction

### Lambda deployment

#### Function code - deployment package

When you create a Lambda function, you package your _function code_ (and its dependencies) into a _deployment package_.

![alt text](/images/diagrams/workshop-5/lambda--deployment-package.drawio.png)

> [!NOTE]
> Lambda supports two types of deployment packages: container images and `.zip` file archives. To simplify, we only consider a Lambda function backed by a `.zip` file archive.

#### Updating function code for a Lambda function

##### Using a local machine

![alt text](/images/diagrams/workshop-5/lambda--update-function-code--local-machine.drawio.png)

##### Using Lambda Console Editor

![alt text](/images/diagrams/workshop-5/lambda--update-function-code--lambda-console-editor.drawio.png)

#### Each version is an immutable snapshot of code + configuration

![alt text](/images/diagrams/workshop-5/lambda--version.drawio.png)

> [!NOTE]
> There is always a version named `$LATEST`. To take a snapshot of the code and the configuration of the `$LATEST` version, you _publish_ **a version** from the `$LATEST` version.

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
> For AWS Lambda, the _wait time_ is the time between: 1. the start of the canary deployment, and 2. the time when the new version is fully weighted (100% traffic is routed to the new version). Usually, it is one of the following values: 5 min, 10 min, 15 min, 30 min.

> [!TIP]
> AWS Lambda integrates with other AWS services to help you monitor and troubleshoot your Lambda functions. Lambda automatically monitors Lambda functions on your behalf and reports metrics through Amazon CloudWatch. To help you monitor your code when it runs, Lambda automatically tracks the number of requests, the invocation duration per request, and the number of requests that result in an error.
