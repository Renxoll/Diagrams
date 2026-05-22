workspace "" "" {

    model {
        investor = person "" "" "Actor"
        financialAdvisor = person "" "" "Actor"

        stripe = softwareSystem "Stripe" "Pasarela de procesamiento de pagos externos." "External System"
        twilio = softwareSystem "Twilio" "Servicio de notificaciones SMS." "External System"
        sageMaker = softwareSystem "" "Modelo de IA para sugerencias de portafolios." "External System"

        microInvestSystem = softwareSystem "" "" "System" {
            
            webApp = container "Single-Page Application" "Provee la interfaz de usuario." "React / TypeScript" "WebBrowser"
            apiGateway = container "API Gateway" "Punto de entrada unificado y balanceador de carga." "Kong / Nginx" "Gateway"
            
            messageBroker = container "Message Broker" "Bus de eventos asíncronos." "RabbitMQ / Apache Kafka" "MessageQueue"

            authService = container "IAM Service" "Gestiona identidades y tokens." "Spring Boot / Java" "HexagonalService"
            investmentService = container "" "Lógica core de " "Spring Boot / Java" "HexagonalService"
            notificationService = container "Notification Service" "Escucha eventos y envía alertas." "Node.js / TypeScript" "HexagonalService"

            authDb = container "IAM Database" "Almacena credenciales." "PostgreSQL" "Database"
            investmentDb = container " Database" "Almacena " "MongoDB" "Database"

            webApp -> apiGateway "Makes API calls to" "JSON/HTTPS"
            
            apiGateway -> authService "Routes auth requests to" "gRPC/HTTPS"
            apiGateway -> investmentService "Routes investment requests to" "gRPC/HTTPS"
            
            authService -> authDb "Reads/Writes" "TCP/IP"
            investmentService -> investmentDb "Reads/Writes" "TCP/IP"
            
            investmentService -> messageBroker "Publishes events to" "AMQP"
            messageBroker -> notificationService "Consumes events from" "AMQP"
        }

        investor -> webApp "Visits and uses" "HTTPS"
        financialAdvisor -> webApp "Manages clients via" "HTTPS"
        
        investmentService -> stripe "Processes payments using" "JSON/HTTPS"
        investmentService -> sageMaker "Requests AI predictions from" "JSON/HTTPS"
        notificationService -> twilio "Sends SMS alerts via" "JSON/HTTPS"
    }

    views {
        systemContext microInvestSystem "SystemContext" {
            include *
            autoLayout tb
            description "Diagrama de Contexto del Sistema MicroInvestAI."
        }

        container microInvestSystem "Containers" {
            include *
            autoLayout tb
            description "Diagrama de Contenedores para la arquitectura de microservicios."
        }

        theme default

        styles {
            element "WebBrowser" {
                shape WebBrowser
                background #08427b
                color #ffffff
            }
            
            element "HexagonalService" {
                shape Hexagon
                background #438dd5
                color #ffffff
            }

            element "Database" {
                shape Cylinder
                background #f2f2f2
                color #000000
            }

            element "MessageQueue" {
                shape Pipe
                background #ff9900
                color #ffffff
            }

            element "External System" {
                background #999999
                color #ffffff
            }

            element "Gateway" {
                shape RoundedBox
                background #1168bd
                color #ffffff
            }
        }
    }
}