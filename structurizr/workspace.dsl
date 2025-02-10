workspace "Name" "Description" {

    !identifiers hierarchical

    model {
        u = person "User"
        ss = softwareSystem "Store System" {
            api = container "API"
            db = container "Data Storage" {
                tags "Database"
            }
        }
        ps = softwareSystem "Payment System"

        u -> ss.api "Uses"
        ss.api -> ss.db "Reads from and writes to"
        ps -> ss.api "Notifies payments events"

        deploymentEnvironment "Dev_Env" {
            deploymentNode "Internet" {
                softwareSystemInstance ps
            }
            deploymentNode "AWS" {
                containerInstance ss.api "" "Amazon Web Services - API Gateway"
                containerInstance ss.db "" "Amazon Web Services - DynamoDB"
            }
        }
    }

    views {
        theme https://static.structurizr.com/themes/amazon-web-services-2023.01.31/theme.json

    }

    configuration {
        scope softwaresystem
    }

}