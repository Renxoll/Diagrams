workspace "Nombre del caso" "Plantilla C4 (Structurizr DSL) - Context + Container. Reemplaza los identificadores y textos entre comillas por los del nuevo caso." {

    model {
        # ACTORES - agrega o quita personas segun el enunciado
        primaryUser = person "Primary User" "Rol principal que interactua con el sistema. Ej: Farmer, Patient, Customer."
        secondaryUser = person "Secondary User" "Rol secundario. Ej: Maintenance Staff, Doctor, Support Agent. Borra si no aplica."

        # SISTEMAS EXTERNOS - reemplaza por los del enunciado (IdP, hubs de mensajeria, terceros)
        identityProvider = softwareSystem "Identity Provider" "Autenticacion y autorizacion (ej. Azure AD, Auth0, Cognito)." "External"
        messagingHub = softwareSystem "Messaging Hub" "Conectividad y mensajeria de eventos/dispositivos externos (ej. Azure IoT Hub, Kafka)." "External"
        externalDevices = softwareSystem "External Devices" "Dispositivos o sistemas de terceros que envian datos. Usa tag IoTDevice solo si son sensores." "External,IoTDevice"

        # SISTEMA PRINCIPAL - el sistema en alcance del caso
        mainPlatform = softwareSystem "Main Platform" "Descripcion de una linea del sistema en alcance, tomada del enunciado." {

            # Clientes
            webApp = container "Web Application" "Cliente web. Ajusta la tecnologia (Angular, React, etc.)." "Angular" "WebApp"
            mobileApp = container "Mobile Application" "Cliente movil. Ajusta la tecnologia (Flutter, React Native, etc.)." "Flutter" "MobileApp"
            apiGateway = container "API Gateway" "Punto unico de entrada; enruta y compone solicitudes a los microservicios." ".NET Core / Azure API Management"

            # Microservicios - uno por bounded context identificado en el Event Storming.
            # Duplica este bloque (servicio + BD) por cada bounded context adicional.
            serviceA = container "Bounded Context A Service" "Responsabilidad del primer bounded context." ".NET Core, CQRS" "Microservice"
            serviceB = container "Bounded Context B Service" "Responsabilidad del segundo bounded context." ".NET Core, CQRS" "Microservice"
            # serviceC = container "Bounded Context C Service" "..." ".NET Core, CQRS" "Microservice"

            edgeGateway = container "Edge Gateway" "Solo si el caso tiene IoT/edge computing; borra el contenedor y sus relaciones si no aplica." "C++"

            serviceADb = container "Bounded Context A Database" "Persistencia del primer bounded context." "SQL Server" "Database"
            serviceBDb = container "Bounded Context B Database" "Persistencia del segundo bounded context." "SQL Server" "Database"
        }

        # RELACIONES - nivel contexto
        primaryUser -> mainPlatform "Accion principal del actor" "HTTPS"
        secondaryUser -> mainPlatform "Accion del actor secundario" "HTTPS"
        externalDevices -> mainPlatform "Envia datos o eventos"
        mainPlatform -> identityProvider "Autentica y autoriza usuarios" "OAuth2/OIDC"
        mainPlatform -> messagingHub "Envia/recibe eventos o telemetria" "AMQPS/MQTT"

        # RELACIONES - nivel contenedor
        primaryUser -> webApp "Usa" "HTTPS"
        primaryUser -> mobileApp "Usa" "HTTPS"
        secondaryUser -> mobileApp "Usa" "HTTPS"

        webApp -> apiGateway "Realiza llamadas API" "JSON/HTTPS"
        mobileApp -> apiGateway "Realiza llamadas API" "JSON/HTTPS"
        apiGateway -> identityProvider "Valida tokens" "OAuth2/OIDC"

        apiGateway -> serviceA "Enruta solicitudes" "JSON/HTTPS"
        apiGateway -> serviceB "Enruta solicitudes" "JSON/HTTPS"

        externalDevices -> edgeGateway "Envia datos crudos" "MQTT"
        edgeGateway -> messagingHub "Envia datos filtrados" "MQTTS"
        messagingHub -> serviceA "Entrega eventos" "AMQPS"

        serviceA -> serviceADb "Lee y escribe" "TCP/SQL"
        serviceB -> serviceBDb "Lee y escribe" "TCP/SQL"
        serviceA -> serviceB "Publica eventos de dominio" "Event bus"
    }

    views {
        systemContext mainPlatform "ContextDiagram" {
            include *
            autoLayout
        }

        container mainPlatform "ContainerDiagram" {
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
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Database" {
                shape Cylinder
            }

            # Shapes opcionales - deja solo los tags que apliquen al nuevo caso, borra el resto
            element "IoTDevice" {
                shape Robot
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
        }
    }
}
