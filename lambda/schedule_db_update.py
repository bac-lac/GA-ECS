import os
import json
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

rds = boto3.client("rds")
sns = boto3.client("sns")

TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]
DB_INSTANCE_ARN = os.environ["DB_INSTANCE_ARN"]


def notify(subject, message):
    sns.publish(
        TopicArn=TOPIC_ARN,
        Subject=subject,
        Message=json.dumps(message, indent=2)
    )


def lambda_handler(event, context):
    try:

        arn = DB_INSTANCE_ARN

        pending = rds.describe_pending_maintenance_actions(
            ResourceIdentifier=arn
        )

        for maintenance in pending.get(
            "PendingMaintenanceActions", []
        ):
            for detail in maintenance.get(
                "PendingMaintenanceActionDetails", []
            ):

                if detail["Action"] == "system-update":

                    rds.apply_pending_maintenance_action(
                        ResourceIdentifier=arn,
                        ApplyAction="system-update",
                        OptInType="next-maintenance"
                    )

                    message = {
                        "status": "scheduled",
                        "database": DB_INSTANCE_ARN,
                        "action": "system-update"
                    }

                    notify(
                        "RDS Maintenance Scheduled",
                        message
                    )

                    return message

        message = {
            "status": "no_pending_update",
            "database": DB_INSTANCE_ARN
        }

        notify(
            "RDS Maintenance Check Complete",
            message
        )

        return message

    except Exception as e:

        error = {
            "status": "error",
            "database": DB_INSTANCE_ARN,
            "message": str(e)
        }

        notify(
            "RDS Maintenance Failure",
            error
        )

        raise