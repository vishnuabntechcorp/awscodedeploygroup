# awscodedeploygroup
codedeploygroup
Here’s an example of how you could define a CronJob that runs the backup daily
apiVersion: batch/v1
kind: CronJob
metadata:
  name: mongodb-backup
spec:
  schedule: "1 * * * *"  # Run daily based on REQ
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: mongodb-backup
            image: mongo:latest
            command:
            - /bin/sh
            - -c
            - |
              mongodump --archive=/data/db/mongodb-backup.archive --gzip &&
              aws s3 cp /data/db/mongodb-backup.archive s3://your-bucket-name/mongodb-backup.archive
          restartPolicy: OnFailure

