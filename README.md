## aws-fullstack-demo

Just a basic full-stack hello world app deployed on AWS and provisioned with Terraform.

#### Architecture

```
User → CloudFront → S3 (React app)
                 → API Gateway → Lambda (NestJS) → DynamoDB
```

| Layer | Service | Purpose |
|---|---|---|
| Frontend hosting | S3 + CloudFront | Serves the React build over HTTPS via OAC |
| API | API Gateway (HTTP API) | Routes requests to Lambda |
| Backend | Lambda (Node 20) | NestJS handler via serverless-express |
| Database | DynamoDB | Todo table |
| Auth | Cognito | User auth + JWT |
| Observability | CloudWatch | Logs + alarms |
| IaC | Terraform | Provisions all AWS resources |

### Deploying

#### Frontend

Build the React app and sync to S3:

```bash
cd frontend
yarn build
aws s3 sync dist/ s3://my-aws-demo-frontend
```

#### Backend

Build and zip the NestJS app for Lambda:

```bash
cd backend
yarn build
zip -r ../infra/lambda.zip dist/ node_modules/
cd ../infra
terraform apply
```

- **OAC (Origin Access Control)** — lets CloudFront access a private S3 bucket without making it public
- **Lambda cold starts** — NestJS bootstraps once and reuses the instance across warm invocations
- **API Gateway HTTP API** — routes requests to Lambda via `AWS_PROXY` integration
- **IAM roles** — Lambda needs an execution role with explicit permissions to invoke and log
- **Terraform state** — infrastructure is described as code and state is tracked locally (remote state via S3 + DynamoDB lock table to be added)

## Roadmap

- [ ] DynamoDB table + Lambda IAM policy
- [ ] Cognito user pool + API Gateway authorizer
- [ ] CloudWatch alarms for Lambda error rate and duration
- [ ] Remote Terraform state (S3 + DynamoDB)
- [ ] GitHub Actions CI/CD with AWS OIDC auth
