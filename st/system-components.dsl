workspace "Plataforma de Microinversiones" "Arquitectura del sistema de inversiones" {

    model {
        // --- NIVEL 1: ACTORES EXTERNOS ---
        investor = person "Investor User" "Usuario que realiza microinversiones a través de la plataforma." "Actor"
        financialAdvisor = person "Financial Advisor" "Agente humano que brinda soporte especial." "Actor"

        // --- NIVEL 1: SISTEMAS EXTERNOS ---
        stripe = softwareSystem "Stripe" "Pasarela de procesamiento de pagos externos." "External System"
        twilio = softwareSystem "Twilio" "Servicio de notificaciones SMS." "External System"
        sageMaker = softwareSystem "AWS SageMaker" "Modelo de IA para sugerencias de portafolios." "External System"

        // --- SISTEMA PRINCIPAL (C4 CONTEXT) ---
        microInvestSystem = softwareSystem "MicroInvestAI Platform" "Plataforma principal de microinversiones y asesoría." "System" {
            
            // --- NIVEL 2: CONTENEDORES (C4 CONTAINERS) ---
            webApp = container "Single-Page Application" "Provee la interfaz de usuario." "React / TypeScript" "WebBrowser"
            apiGateway = container "API Gateway" "Punto de entrada unificado y balanceador de carga." "Kong / Nginx" "Gateway"
            
            messageBroker = container "Message Broker" "Bus de eventos asíncronos." "RabbitMQ / Apache Kafka" "MessageQueue"

            // Microservicios (Etiquetados como Hexagonales)
            authService = container "Authentication Service" "Gestiona identidades y tokens." "Spring Boot / Java" "HexagonalService"
            investmentService = container "Investment Service" "Lógica core de portafolios e inversiones." "Spring Boot / Java" "HexagonalService"
            notificationService = container "Notification Service" "Escucha eventos y envía alertas." "Node.js / TypeScript" "HexagonalService"

            // Bases de datos (Desacopladas)
            authDb = container "Auth Database" "Almacena credenciales." "PostgreSQL" "Database"
            investmentDb = container "Investment Database" "Almacena historiales y portafolios." "MongoDB" "Database"

            // Relaciones internas (Containers)
            webApp -> apiGateway "Makes API calls to" "JSON/HTTPS"
            
            apiGateway -> authService "Routes auth requests to" "gRPC/HTTPS"
            apiGateway -> investmentService "Routes investment requests to" "gRPC/HTTPS"
            
            authService -> authDb "Reads/Writes" "TCP/IP"
            investmentService -> investmentDb "Reads/Writes" "TCP/IP"
            
            investmentService -> messageBroker "Publishes events to" "AMQP"
            messageBroker -> notificationService "Consumes events from" "AMQP"
        }

        // --- RELACIONES NIVEL 1 (Context) ---
        investor -> webApp "Visits and uses" "HTTPS"
        financialAdvisor -> webApp "Manages clients via" "HTTPS"
        
        investmentService -> stripe "Processes payments using" "JSON/HTTPS"
        investmentService -> sageMaker "Requests AI predictions from" "JSON/HTTPS"
        notificationService -> twilio "Sends SMS alerts via" "JSON/HTTPS"
    }

    views {
        // Vista de Contexto (Nivel 1)
        systemContext microInvestSystem "SystemContext" {
            include *
            autoLayout tb
            description "Diagrama de Contexto del Sistema MicroInvestAI."
        }

        // Vista de Contenedores (Nivel 2)
        container microInvestSystem "Containers" {
            include *
            autoLayout tb
            description "Diagrama de Contenedores para la arquitectura de microservicios."
        }

        theme default

        // --- ESTILOS VISUALES ---
        styles {
            // Estilo para la aplicación Web (Forma de navegador)
            element "WebBrowser" {
                shape WebBrowser
                background #08427b
                color #ffffff
            }
            
            // Estilo para los Microservicios Hexagonales
            element "HexagonalService" {
                shape Hexagon
                background #438dd5
                color #ffffff
            }

            // Estilo para Bases de Datos (Forma de cilindro)
            element "Database" {
                shape Cylinder
                background #f2f2f2
                color #000000
            }

            // Estilo para el Bus de Mensajes (Forma de tubería/cola)
            element "MessageQueue" {
                shape Pipe
                background #ff9900
                color #ffffff
            }

            // Estilo para Sistemas Externos (Gris para diferenciarlos)
            element "External System" {
                background #999999
                color #ffffff
            }

            // Estilo para el API Gateway
            element "Gateway" {
                shape RoundedBox
                background #1168bd
                color #ffffff
            }
        }
    }
}