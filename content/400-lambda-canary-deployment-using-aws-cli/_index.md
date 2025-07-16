---
title: "Lambda canary deployment using AWS CLI"
weight: 4
chapter: false
pre: " <b> 4. </b> "
---

Just as when deploy a Lambda function, there are 2 scenarios when you perform a canary deployment:

1. **Initial Canary Deployment**: When performing a canary deployment for the first time (all traffic will be routed to the first version)
2. **Canary Deployment**: When updating the code of an existing Lambda function (and shift a part of traffic to the new version)
