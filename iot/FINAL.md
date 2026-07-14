# Repaso Examen Final — ModestIoT en Arduino C++

---

## 1. Arquitectura ModestIoT vs Manual

| Concepto | Manual (PC1) | ModestIoT (PC2) |
|---|---|---|
| Clase base | Tu `Sensor.h` y `Actuator.h` | Librería `ModestIoT` |
| Orquestador | Tu `Device.h` | `class MiDevice : public Device` |
| Reglas | `EventHandler.evaluate()` | `on(Event event)` |
| Registrar sensores | Manual en `loop()` | `appendSensorToScheduler()` |
| Loop | `device.loop()` | `vTaskDelay()` |
| Instancia | `Device device;` | `static MiDevice* device = nullptr;` |

---

## 2. Estructura de archivos

```
sketch.ino       ← solo instancia y delega
MiDevice.h       ← toda la lógica aquí
```

---

## 3. Plantilla base — MiDevice.h

```cpp
#include <ModestIoT.h>
#include <ArduinoJson.h>
#include <WiFi.h>

// Pin definitions
#define SENSOR_PIN       4
#define TRIG_PIN         5
#define ECHO_PIN         18
#define ACTUATOR_PIN     19
#define RELAY_PIN        21
#define LED_PIN          22
#define BUTTON_PLUS_PIN  23
#define BUTTON_MINUS_PIN 26

class MiDevice : public Device {
private:
    // Sensores
    [TipoSensor]     _sensor;
    UltrasonicSensor _proxSensor;

    // Actuadores
    [TipoActuador]   _actuador;
    RelayModule      _relay;
    Led              _led;
    PushButton       _buttonPlus;
    PushButton       _buttonMinus;

    // Estado
    float         _idealValue;
    String        _operationMode;
    unsigned long _lastPrintTime;

    void printStatus() {
        StaticJsonDocument<256> doc;
        doc["deviceMacAddress"] = WiFi.macAddress();
        doc["operationMode"]    = _operationMode;
        doc["idealValue"]       = _idealValue;
        doc["currentValue"]     = _sensor.getValue();
        doc["distance"]         = _proxSensor.getValue();

        String output;
        serializeJsonPretty(doc, output);
        Serial.println(output);
    }

public:
    MiDevice()
        : Device(2000, 0),
          _sensor(SENSOR_PIN, this),
          _proxSensor(TRIG_PIN, ECHO_PIN, this),
          _actuador(ACTUATOR_PIN, this),
          _relay(RELAY_PIN, this),
          _led(LED_PIN, this),
          _buttonPlus(BUTTON_PLUS_PIN, this),
          _buttonMinus(BUTTON_MINUS_PIN, this),
          _idealValue(0.0),
          _operationMode("STAND_BY"),
          _lastPrintTime(0)
    {
        initializeAsynchronousEngine(16);
        appendSensorToScheduler(&_sensor,     Sensor::MEASURE_DATA_REQUESTED_EVENT_IDENTIFIER);
        appendSensorToScheduler(&_proxSensor, Sensor::MEASURE_DATA_REQUESTED_EVENT_IDENTIFIER);
    }

    void on(Event event) override {
        if (event.identifier == Sensor::DATA_READ_EVENT_IDENTIFIER) {
            float distance = _proxSensor.getValue();

            // Modo 1 — condición de stand by
            if (distance >= UMBRAL_STANDBY) {
                _operationMode = "STAND_BY";
                _relay.deactivate();
                _led.deactivate();
                unsigned long now = millis();
                if (now - _lastPrintTime >= 5000) {
                    printStatus();
                    _lastPrintTime = now;
                }
                return;
            }

            // Modo 2 — modo activo
            _operationMode = "ACTIVE";
            float value = _sensor.getValue();

            if (value >= _idealValue) {
                _led.activate();
                _relay.deactivate();
            } else {
                _led.deactivate();
                _relay.activate();
            }

            unsigned long now = millis();
            if (now - _lastPrintTime >= 5000) {
                printStatus();
                _lastPrintTime = now;
            }
        }
    }
};
```

---

## 4. sketch.ino (siempre igual)

```cpp
#include "MiDevice.h"

static MiDevice* device = nullptr;

void setup() {
    Serial.begin(115200);
    Serial.println("================================");
    Serial.println("  Empresa Inc.");
    Serial.println("  Developer: Renzo Llerena");
    Serial.println("================================");
    device = new MiDevice();
}

void loop() {
    vTaskDelay(pdMS_TO_TICKS(60000));
}
```

---

## 5. Sensores disponibles en ModestIoT

| Sensor | Clase | Constructor | Librería extra |
|---|---|---|---|
| DS18B20 temperatura | `TemperatureSensor` | `(pin, this)` | `OneWire`, `DallasTemperature` |
| DHT22 temperatura | `DhtSensor` | `(pin, this)` | `DHT sensor library` |
| HC-SR04 distancia | `UltrasonicSensor` | `(trigPin, echoPin, this)` | — |

---

## 6. Actuadores disponibles en ModestIoT

| Actuador | Clase | Constructor | Métodos clave |
|---|---|---|---|
| Relay | `RelayModule` | `(pin, this)` | `activate()`, `deactivate()` |
| LED | `Led` | `(pin, this)` | `activate()`, `deactivate()` |
| LED bar graph | `LedBarGraph` | `(pin, this)` | `activate()`, `deactivate()` |
| Servo motor | `ServoMotor` | `(pin, this)` | `activate()`, `deactivate()` |
| LCD I2C | `CharacterLcdDisplay` | `(addr, cols, rows, this)` | `setLineBuffer()`, `handle()` |
| Botón | `PushButton` | `(pin, this)` | detectado via `on()` |

---

## 7. Casos practicados

| Caso | Sensor temp | Sensor prox | Umbral prox | Modo 1 | Modo 2 | Umbral temp |
|---|---|---|---|---|---|---|
| **Ember** | `TemperatureSensor` DS18B20 | HC-SR04 | >= 18cm | STAND_BY | ACTIVE | >= 54°C → OK |
| **FreshBox** | `DhtSensor` DHT22 | HC-SR04 | < 5cm | OPEN | CLOSED | <= 5°C → OK |

---

## 8. Conexiones diagram.json por componente

### DS18B20
```json
{ "type": "wokwi-ds18b20", "id": "temp1", "attrs": {} }
[ "temp1:VCC", "esp:3V3", "red", [] ],
[ "temp1:GND", "esp:GND.1", "black", [] ],
[ "temp1:DQ",  "esp:4",    "green", [] ]
```

### DHT22
```json
{ "type": "wokwi-dht22", "id": "dht1", "attrs": {} }
[ "dht1:VCC", "esp:5V",    "red",   [] ],
[ "dht1:GND", "esp:GND.1", "black", [] ],
[ "dht1:SDA", "esp:4",     "green", [] ]
```

### HC-SR04
```json
{ "type": "wokwi-hc-sr04", "id": "ultrasonic1", "attrs": {} }
[ "ultrasonic1:VCC",  "esp:5V",    "red",   [] ],
[ "ultrasonic1:GND",  "esp:GND.2", "black", [] ],
[ "ultrasonic1:TRIG", "esp:5",     "green", [] ],
[ "ultrasonic1:ECHO", "esp:18",    "blue",  [] ]
```

### LED bar graph
```json
{ "type": "wokwi-led-bar-graph", "id": "bargraph1", "attrs": { "color": "yellow" } }
[ "bargraph1:GND", "esp:GND.3", "black",  [] ],
[ "bargraph1:A1",  "esp:19",    "yellow", [] ]
```

### Relay module
```json
{ "type": "wokwi-relay-module", "id": "relay1", "attrs": {} }
[ "relay1:VCC", "esp:5V",    "red",    [] ],
[ "relay1:GND", "esp:GND.1", "black",  [] ],
[ "relay1:IN",  "esp:21",    "orange", [] ]
```

### LED
```json
{ "type": "wokwi-led", "id": "led1", "attrs": { "color": "yellow" } }
[ "led1:A", "esp:22",    "yellow", [] ],
[ "led1:C", "esp:GND.1", "black",  [] ]
```

### Servo motor
```json
{ "type": "wokwi-servo", "id": "servo1", "attrs": {} }
[ "servo1:PWM", "esp:19",    "orange", [] ],
[ "servo1:V+",  "esp:5V",    "red",    [] ],
[ "servo1:GND", "esp:GND.1", "black",  [] ]
```

### LCD I2C
```json
{ "type": "wokwi-lcd1602", "id": "lcd1", "attrs": { "pins": "i2c" } }
[ "lcd1:SDA", "esp:SDA",   "blue",   [] ],
[ "lcd1:SCL", "esp:SCL",   "yellow", [] ],
[ "lcd1:VCC", "esp:5V",    "red",    [] ],
[ "lcd1:GND", "esp:GND.2", "black",  [] ]
```

### Pushbuttons
```json
{ "type": "wokwi-pushbutton", "id": "btn1", "attrs": { "color": "green" } }
[ "btn1:1.l", "esp:23",    "green", [] ],
[ "btn1:2.l", "esp:GND.1", "black", [] ],
[ "btn2:1.l", "esp:26",    "green", [] ],
[ "btn2:2.l", "esp:GND.1", "black", [] ]
```

---

## 9. Errores más comunes

| Error | Correcto |
|---|---|
| `#define PIN = 4` | `#define PIN 4` |
| `TemperatureSensor` para DHT22 | `DhtSensor` |
| `TEMP_PIN` cuando es DHT | `DHT_PIN` |
| Constructor fuera de la clase | Constructor dentro de `public` |
| `Sensor::MEASURE_DATA_REQUEST_EVENT_IDENTIFIER` | `Sensor::MEASURE_DATA_REQUESTED_EVENT_IDENTIFIER` |
| `delay()` en loop | `vTaskDelay(pdMS_TO_TICKS(60000))` |
| `Device device;` | `static MiDevice* device = nullptr;` |
| `device.setup()` | `device = new MiDevice();` |
| LCD sin `"pins": "i2c"` | `"attrs": { "pins": "i2c" }` |
| Copiar JSON keys del caso anterior | Adaptar keys al caso actual |

---

## 10. Checklist para el examen

- [ ] `#define` sin `=`
- [ ] Clase hereda de `Device` de ModestIoT
- [ ] Sensor correcto según el hardware (DS18B20 vs DHT22)
- [ ] Constructor inicializa todos los atributos
- [ ] `initializeAsynchronousEngine(16)` en constructor
- [ ] `appendSensorToScheduler()` para cada sensor
- [ ] `on()` evalúa primero distancia, luego temperatura
- [ ] `return` después del bloque STAND_BY/OPEN
- [ ] `printStatus()` en ambos bloques con timer de 5000ms
- [ ] JSON keys en inglés y acordes al caso
- [ ] `sketch.ino` usa `new` y `vTaskDelay`
- [ ] Info de empresa en `Serial` al inicio
- [ ] LCD con `"pins": "i2c"` en diagram.json
- [ ] LED y LED bar graph en color amarillo si el caso lo pide
