workspace "GreenSense" "Plataforma de Gestión Ambiental Inteligente" {



  model {

    # 1. Definición de Usuarios (Personas)

    facilityManager = person "Facility Manager" "Configura parámetros, zonas y analiza datos históricos ambientales." "Person"

    techInterno = person "Técnico en Campo (Interno)" "Valida el estado de sensores y toma acciones correctivas in situ." "Person"

    partnerSupply = person "Partner de Suministro" "Programa reabastecimientos de filtros y repuestos." "Person"

    partnerMaint = person "Partner de Mantenimiento" "Asigna tareas y ejecuta mantenimientos correctivos." "Person"



    # 2. Sistemas Externos (Partners y Hardware Físico)

    sysInventory = softwareSystem "Partner Inventory System" "Sistema de inventario externo para gestión de repuestos de calidad de aire." "External"

    sysTickets = softwareSystem "Partner Service Orders" "Sistema de tickets externo para mantenimiento." "External"

     

    # El hardware físico ahora es un Sistema Externo que interactúa con nuestro software embebido

    iotHardware = softwareSystem "IoT Hardware (Physical)" "Sensores (DHT-22, MH-Z19B) y Actuadores (Micro Servos, LCD 1602)." "External"



    # 3. Plataforma Central GreenSense (Edge y Nube)

    greensenseSystem = softwareSystem "GreenSense Platform" "Core de monitoreo e integración ambiental." {

       

      # --- INFRAESTRUCTURA LOCAL (EDGE & EMBEDDED) ---

      embeddedAirStation = container "Air Quality Embedded App" "Lógica C++ en ESP32. Orquesta la lectura de aire." "C/C++" "EmbeddedApp"

      embeddedVentController = container "Ventilation Embedded App" "Lógica C++ en ESP32. Orquesta la ventilación." "C/C++" "EmbeddedApp"

       

      edgeNode = container "Estación Base (Edge Gateway)" "Consolida telemetría, ejecuta reglas locales (<2000ms)." "Python / Node.js" "EdgeNode"

      edgeDb = container "Edge Local Database" "Buffer temporal por pérdida de conexión." "SQLite" "Database"



      # --- INFRAESTRUCTURA NUBE (CLOUD) ---

      # Frontends

      webAdmin = container "Environmental Management Web" "SPA para configuración de zonas y alertas." "React / TypeScript" "WebBrowser"

      appMobile = container "Environmental Monitoring App" "App móvil para validación in situ." "Flutter" "MobileApp"

      webPartners = container "Partner Integration Portal" "Portal web para proveedores." "React" "WebBrowser"

       

      # API Gateway (Puerta de enlace)

      apiGateway = container "API Gateway" "Enruta peticiones, maneja autenticación perimetral y balanceo de carga." "Spring Cloud Gateway" "Gateway"



      # Microservicios (Hexagonales) por Dominio (DDD)

      msAuth = container "IAM Service" "Gestiona identidades, roles y tokens JWT." "Go" "Microservice"

      msTelemetry = container "Telemetry & Rules Service" "Ingesta alta transaccionalidad de sensores y evalúa límites críticos." "Java Spring Boot" "Microservice"

      msFacility = container "Facility Management Service" "Gestiona la jerarquía de edificios, zonas y configuraciones." "Java Spring Boot" "Microservice"

      msPartners = container "Partner Integration Service" "Orquesta la comunicación B2B externa." "Node.js" "Microservice"

       

      # Bases de Datos Aisladas (Database-per-Service)

      dbAuth = container "Identity DB" "Almacena credenciales y roles." "PostgreSQL" "Database"

      dbTelemetry = container "Time-Series DB" "Almacena métricas de CO2, temp y humedad." "InfluxDB" "Database"

      dbFacility = container "Facility DB" "Almacena datos estructurales (Edificios, Zonas)." "PostgreSQL" "Database"

      dbPartners = container "Partners DB" "Almacena logs B2B y mapeos de integración." "MongoDB" "Database"

    }



    # 4. Relaciones de Usuarios hacia los Frontends

    facilityManager -> webAdmin "Configura zonas y visualiza dashboards en" "HTTPS"

    techInterno -> appMobile "Revisa alertas activas en" "HTTPS"

    partnerSupply -> webPartners "Revisa filtros en" "HTTPS"

    partnerMaint -> webPartners "Visualiza averías en" "HTTPS"



    # 5. Relaciones de Frontends hacia el API Gateway

    webAdmin -> apiGateway "Envía peticiones HTTP a" "JSON/HTTPS"

    appMobile -> apiGateway "Envía peticiones HTTP a" "JSON/HTTPS"

    webPartners -> apiGateway "Envía peticiones HTTP a" "JSON/HTTPS"



    # 6. Enrutamiento del API Gateway hacia Microservicios

    apiGateway -> msAuth "Delega validación de tokens a" "gRPC/TCP"

    apiGateway -> msTelemetry "Enruta consultas de analíticas a" "HTTP"

    apiGateway -> msFacility "Enruta gestión de zonas a" "HTTP"

    apiGateway -> msPartners "Enruta consultas de partners a" "HTTP"



    # 7. Relaciones de Microservicios a Bases de Datos

    msAuth -> dbAuth "Lee/Escribe usuarios en" "TCP"

    msTelemetry -> dbTelemetry "Lee/Escribe métricas en" "TCP"

    msFacility -> dbFacility "Lee/Escribe estructuras en" "TCP"

    msPartners -> dbPartners "Lee/Escribe registros B2B en" "TCP"



    # 8. Relaciones B2B Externas

    msPartners -> sysInventory "Sincroniza repuestos con" "REST/JSON"

    msPartners -> sysTickets "Genera órdenes de mantenimiento en" "REST/JSON"



    # 9. Relaciones Físicas: Hardware IoT Físico <-> Embedded Apps (Software)

    iotHardware -> embeddedAirStation "Envía lecturas de Temp, Humedad y CO2 a" "Señal Digital / UART"

    iotHardware -> embeddedVentController "Envía lecturas ambientales locales a" "Señal Digital"

    embeddedVentController -> iotHardware "Controla servos y actualiza pantalla en" "PWM / I2C"



    # 10. Relaciones Edge y Embebidos

    embeddedAirStation -> edgeNode "Transmite lecturas procesadas a" "Serial/MQTT Local"

    edgeNode -> embeddedVentController "Envía reglas de actuación hacia" "Serial/MQTT Local"

    edgeNode -> edgeDb "Guarda buffer temporal en" "Local I/O"



    # 11. Relación Edge to Cloud (Atravesando el Gateway)

    edgeNode -> apiGateway "Publica telemetría sincronizada hacia" "MQTT/WSS"

  }



  views {

    container greensenseSystem "C4_Containers_GreenSense_Microservices" "Diagrama de Contenedores - Arquitectura Microservicios Completa" {

      include *

      autoLayout tb

    }



    styles {

      element "Person" {

        background #08427b

        color #ffffff

        shape Person

      }

      element "Gateway" {

        background #5e5e5e

        color #ffffff

        shape Cylinder

      }

      element "Microservice" {

        background #852b99

        color #ffffff

        shape Hexagon

      }

      element "WebBrowser" {

        shape WebBrowser

      }

      element "MobileApp" {

        shape MobileDeviceLandscape

      }

      element "Database" {

        shape Cylinder

      }

      element "External" {

        background #999999

        color #ffffff

        shape RoundedBox

      }

      element "EdgeNode" {

        background #1168bd

        color #ffffff

        shape Box

      }

      element "EmbeddedApp" {

        background #2b6045

        color #ffffff

        shape Component

      }

    }

  }

}