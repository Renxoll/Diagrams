workspace "Smart Farming Solutions" "C4 model for the SFS IoT & Digital Twins platform" {

    model {
        farmer = person "Farmer" "Manages farm resources and monitors digital twins remotely."
        maintenanceStaff = person "Maintenance Staff" "Receives predictive maintenance alerts and performs repairs."

        azureAD = softwareSystem "Azure Active Directory" "Provides authentication and authorization." "External"
        azureIoTHub = softwareSystem "Azure IoT Hub" "Manages connectivity and telemetry for IoT devices." "External"
        iotDevices = softwareSystem "IoT Sensors & Agricultural Machines" "Field sensors and machines (tractors, seeders, harvesters) that collect soil, weather and equipment data." "External,IoTDevice"

        sfsPlatform = softwareSystem "SFS Platform" "Enables smart farming through IoT sensor monitoring, digital twins and predictive resource optimization." {

            webApp = container "Web Application" "Allows farmers to manage farms, view digital twins and reports from a PC." "Angular" "WebApp"
            mobileApp = container "Mobile Application" "Allows farmers to monitor farm and machine conditions remotely." "Flutter" "MobileApp"
            apiGateway = container "API Gateway" "Single entry point that routes and composes requests to backend microservices." ".NET Core / Azure API Management"

            resourceOptimizationService = container "Resource Optimization Service" "Computes optimal irrigation and fertilization strategies from sensor data; runs dynamic simulations." ".NET Core, CQRS" "Microservice"
            digitalTwinService = container "Digital Twin Service" "Maintains virtual replicas of farms and machines, updated in real time." ".NET Core, CQRS" "Microservice"
            predictiveMaintenanceService = container "Predictive Maintenance Service" "Analyzes machine telemetry to detect anomalies and trigger maintenance alerts." ".NET Core, CQRS" "Microservice"
            sensorIngestionService = container "Sensor Data Ingestion Service" "Receives and processes IoT telemetry events coming from Azure IoT Hub." ".NET Core, CQRS" "Microservice"
            edgeGateway = container "Edge Computing Gateway" "Filters and pre-processes raw sensor data on-site before sending it to the cloud." "C++"

            resourceOptimizationDb = container "Resource Optimization Database" "Stores soil moisture, temperature and irrigation/fertilization strategy data." "SQL Server" "Database"
            digitalTwinDb = container "Digital Twin Database" "Stores farm and machine digital twin state." "SQL Server" "Database"
            predictiveMaintenanceDb = container "Predictive Maintenance Database" "Stores equipment telemetry history and maintenance alerts." "SQL Server" "Database"
            sensorDataDb = container "Sensor Data Database" "Stores raw and processed sensor telemetry." "SQL Server" "Database"
        }

        # context-level relationships
        farmer -> sfsPlatform "Manages farms, monitors digital twins and views reports" "HTTPS"
        maintenanceStaff -> sfsPlatform "Receives predictive maintenance alerts" "HTTPS"
        iotDevices -> sfsPlatform "Sends soil, weather and equipment telemetry"
        sfsPlatform -> azureAD "Authenticates and authorizes users" "OAuth2/OIDC"
        sfsPlatform -> azureIoTHub "Sends and receives device telemetry and commands" "MQTT/AMQPS"

        # container-level relationships
        farmer -> webApp "Uses" "HTTPS"
        farmer -> mobileApp "Uses" "HTTPS"
        maintenanceStaff -> mobileApp "Views alerts on" "HTTPS"

        webApp -> apiGateway "Makes API calls to" "JSON/HTTPS"
        mobileApp -> apiGateway "Makes API calls to" "JSON/HTTPS"
        apiGateway -> azureAD "Validates tokens with" "OAuth2/OIDC"

        apiGateway -> resourceOptimizationService "Routes requests to" "JSON/HTTPS"
        apiGateway -> digitalTwinService "Routes requests to" "JSON/HTTPS"
        apiGateway -> predictiveMaintenanceService "Routes requests to" "JSON/HTTPS"

        iotDevices -> edgeGateway "Sends raw sensor readings" "MQTT"
        edgeGateway -> azureIoTHub "Sends filtered telemetry" "MQTTS"
        azureIoTHub -> sensorIngestionService "Delivers telemetry events" "AMQPS"

        sensorIngestionService -> sensorDataDb "Reads from and writes to" "TCP/SQL"
        sensorIngestionService -> resourceOptimizationService "Publishes sensor data events" "Event bus"
        sensorIngestionService -> digitalTwinService "Publishes sensor data events" "Event bus"
        sensorIngestionService -> predictiveMaintenanceService "Publishes machine telemetry events" "Event bus"

        resourceOptimizationService -> resourceOptimizationDb "Reads from and writes to" "TCP/SQL"
        digitalTwinService -> digitalTwinDb "Reads from and writes to" "TCP/SQL"
        predictiveMaintenanceService -> predictiveMaintenanceDb "Reads from and writes to" "TCP/SQL"
    }

    views {
        systemContext sfsPlatform "ContextDiagram" {
            include *
            autoLayout
        }

        container sfsPlatform "ContainerDiagram" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "IoTDevice" {
                shape Robot
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Microservice" {
                shape Hexagon
            }
            element "WebApp" {
                shape WebBrowser
            }
            element "MobileApp" {
                shape MobileDevicePortrait
            }
            element "Database" {
                shape Cylinder
            }
        }
    }
}
