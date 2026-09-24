# Introduction
This project is a proof of concept for GoAnywhere.

# Build Instructions

## Container Image Build
Run the following commands from the project root directory:
```
docker build -t ga:latest --file docker/Dockerfile .
```

## Environment Variables
The following environment variables are used to control the application at run-time. Mandatory variables are marked with an asterisk.

> ACCOUNT *: The AWS account number.
- Default value: ACCOUNT

> ADMIN_DB_USERNAME *: The DB username for RDS.
- Default value: ADMIN_DB_USERNAME

> ADMIN_DB_PASSWORD *: The DB password for RDS.
- Default value: ADMIN_DB_PASSWORD

> CERT_BODY *: The certificate body.
- Default value: CERT_BODY

> CERT_CHAIN *: The certificate chain.
- Default value: CERT_CHAIN

> CERT_PRIVATE_KEY *: The certificate private key.
- Default value: CERT_PRIVATE_KEY

> CLOUDWATCH_EMAIL *: The email used for cloudwatch endpoint.
- Default value: cloudwatch_email@domain.com

> DAMS_EMAIL *: The email used for cloudwatch endpoint (DAMS).
- Default value: dams_email@domain.com

> DB_ALLOCATED_STORAGE *: The allocated storage for the database in GB.
- Default value: 20

> DB_BACKUP_WINDOW *: The backup window for the database. (UTC)
- Default value: 07:00-08:00

> DB_ENGINE_VERSION *: The database engine version for the application.
- Default value: 8.4

> DB_INSTANCE_CLASS *: The database intance class for the application.
- Default value: db.t3.medium

> DB_INSTANCE_CLASS_MEMORY *: The database intance class available memory in GB.
- Default value: 4

> DB_MAINTENANCE_WINDOW *: The maintenance window for the database. (UTC)
- Default value: sat:05:00-sat:06:00

> ECR_IMAGE: The ECR image name used for the task definition. This value is auto-generated.
- Default value: ECR_IMAGE

> ENV *: The environment in which to deploy the solution.
- Default value: dev
- Allowed values: dev, test or prod

> EXTERNAL_ID *: External ID of the automation account role.
- Default value: EXTERNAL_ID

> MFT_CLUSTER *: If set to true, this will start the application in cluster mode.
- Default value: TRUE

> PROFILE_DAMS_ROLE_ARN: The role ARN for the DAMS account.
- Default value: PROFILE_DAMS_ROLE_ARN

> PROFILE_DATAS3_ROLE_ARN: The role ARN for the DATAS3 account.
- Default value: PROFILE_DATAS3_ROLE_ARN

> ROLE_ARN *: ARN of the role used by terraform..
- Default value: ROLE_ARN

> TASK_DEFINITION_CPU *: The task definition CPU.
- Default value: 1024

> TASK_DEFINITION_MEMORY *: The task definition memory.
- Default value: 3072

## Run the Application Locally

1. Build the application container as per the above [Container Image Build](#container-image-build) instructions.
1. cp ./docker/example.env ./docker/local.env
1. Edit the local.env as required.
1. Run the following command from the project **docker** directory:
    ```
    docker compose up -d
    ```

# Code Check
[Checkov](https://www.checkov.io/)
[shellcheck](https://github.com/koalaman/shellcheck#how-to-use)