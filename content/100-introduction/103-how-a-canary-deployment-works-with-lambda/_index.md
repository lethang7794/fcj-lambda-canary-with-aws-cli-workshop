---
title: "Canary deployment and AWS Lambda"
weight: 3
chapter: false
pre: " <b> 1.3. </b> "
---

### What is canary deployment?

Canary deployment means you shift traffic to a new version of your application in small increments, and monitor the application for any issues before shifting all traffic to the new version.

### How a canary deployment works with Lambda?

![alt text](/images/diagrams/workshop-5/lambda--how-canary-deployment-work.drawio.png)

- To verify that the new version is healthy, you can use CloudWatch alarms to monitor the [invocation metrics](https://docs.aws.amazon.com/lambda/latest/dg/monitoring-metrics-types.html#invocation-metrics) `Errors`

> [!NOTE]
> For AWS Lambda, the _wait time_ is the time between: 1. the start of the canary deployment, and 2. the time when the new version is fully weighted (100% traffic is routed to the new version). Usually, it is one of the following values: 5 min, 10 min, 15 min, 30 min.

> [!TIP]
> AWS Lambda integrates with other AWS services to help you monitor and troubleshoot your Lambda functions. Lambda automatically monitors Lambda functions on your behalf and reports metrics through Amazon CloudWatch. To help you monitor your code when it runs, Lambda automatically tracks the number of requests, the invocation duration per request, and the number of requests that result in an error.
