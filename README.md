# azuredevops-pipeline-deployment

A template for constructing Azure DevOps content deployment pipelines to RStudio Connect

To use this template, add a content directory `content-dir` to hold your content code and manifest file:

```
.
├── README.md
├── azure-pipelines.yml
├── content-dir
│   ├── app.R
│   └── manifest.json
├── cookie.txt
├── create-upload-deploy.sh
└── optional-steps
    ├── runas-user.sh
    ├── set-vanity-url.sh
    └── update-acl.sh
```

!! Reminder: Don't forget to add a pipeline status badge
