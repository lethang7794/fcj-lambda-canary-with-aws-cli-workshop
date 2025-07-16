---
title: "Lambda deployment"
weight: 1
chapter: false
pre: " <b> 1.1. </b> "
---

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
