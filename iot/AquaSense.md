# Repaso AquaSense Smart Tank Controller
## Examen IoT — ModestIoT + OOP en Arduino C++

---

## 1. Arquitectura general

```
sketch.ino
    └── Device
            ├── UltrasonicSensor  (hereda Sensor)
            ├── ServoValve        (hereda Actuator)
            ├── EventHandler
            └── Command
```

**Regla clave:** `sketch.ino` solo instancia `Device` y delega. Nada más.

---

## 2. Clases abstractas

Una clase abstracta define **QUÉ** debe hacer algo, pero no **CÓMO**.

```cpp
// Sensor.h
class Sensor {
public:
    virtual void begin() = 0;   // = 0 significa OBLIGATORIO implementar
    virtual float read() = 0;
};

// Actuator.h
class Actuator {
public:
    virtual void begin() = 0;
    virtual void activate() = 0;
    virtual void deactivate() = 0;
};
```

**Reglas:**
- `virtual` + `= 0` → método puramente virtual (abstracto)
- Los métodos van en `public`
- Los atributos van en `private`

---

## 3. UltrasonicSensor.h

```cpp
#include "Sensor.h"

class UltrasonicSensor : public Sensor {
private:
    int _trigPin;
    int _echoPin;

public:
    UltrasonicSensor(int trigPin, int echoPin)
        : _trigPin(trigPin), _echoPin(echoPin) {}

    void begin() override {
        pinMode(_trigPin, OUTPUT);
        pinMode(_echoPin, INPUT);
    }

    float read() override {
        // 1. Disparar pulso
        digitalWrite(_trigPin, LOW);
        delayMicroseconds(2);
        digitalWrite(_trigPin, HIGH);
        delayMicroseconds(10);
        digitalWrite(_trigPin, LOW);

        // 2. Medir tiempo de eco
        long tiempo_echo = pulseIn(_echoPin, HIGH);

        // 3. Convertir a distancia y nivel
        float distancia = tiempo_echo * 0.034 / 2;
        float nivel = ((20.0 - distancia) / 20.0) * 100.0;

        return constrain(nivel, 0.0, 100.0);
    }
};
```

**Fórmulas clave:**
```
distancia (cm) = tiempo_echo × 0.034 / 2
nivel (%)      = ((altura_tanque - distancia) / altura_tanque) × 100
```

**Funciones Arduino usadas:**
| Función | Qué hace |
|---|---|
| `digitalWrite(pin, HIGH/LOW)` | Envía señal al pin |
| `delayMicroseconds(n)` | Espera n microsegundos |
| `pulseIn(pin, HIGH)` | Mide tiempo que el pin está en HIGH |
| `constrain(val, min, max)` | Limita valor a un rango |

---

## 4. ServoValve.h

```cpp
#include <ESP32Servo.h>
#include "Actuator.h"

class ServoValve : public Actuator {
private:
    int _pin;
    bool _isOpen;
    Servo _servo;

public:
    ServoValve(int pin) : _pin(pin), _isOpen(false) {}

    void begin() override {
        _servo.attach(_pin);
        deactivate(); // arranca cerrado
    }

    void activate() override {
        _servo.write(90); // 90° = abierto
        _isOpen = true;
    }

    void deactivate() override {
        _servo.write(0);  // 0° = cerrado
        _isOpen = false;
    }

    bool isOpen() {       // NO es override, es método nuevo
        return _isOpen;
    }
};
```

---

## 5. EventHandler.h

```cpp
#include "ServoValve.h"

class EventHandler {
private:
    ServoValve* _valve;  // puntero

public:
    EventHandler(ServoValve* valve) : _valve(valve) {}

    void evaluate(float waterLevel) {
        if (waterLevel < 25.0) {
            _valve->activate();   // -> porque es puntero
        } else if (waterLevel > 95.0) {
            _valve->deactivate();
        }
    }
};
```

**Regla de umbrales:**
```
nivel < 25%  → abrir válvula
nivel > 95%  → cerrar válvula
```

---

## 6. Command.h

```cpp
#include "ServoValve.h"

class Command {
private:
    ServoValve* _valve;

public:
    Command(ServoValve* valve) : _valve(valve) {}

    void execute(String cmd) {
        if (cmd == "OPEN") {
            _valve->activate();
        } else if (cmd == "CLOSE") {
            _valve->deactivate();
        }
    }
};
```

---

## 7. Device.h

```cpp
#include "UltrasonicSensor.h"
#include "ServoValve.h"
#include "EventHandler.h"
#include "Command.h"
#include <WiFi.h>
#include <HTTPClient.h>

#define TRIG_PIN  5
#define ECHO_PIN  18
#define SERVO_PIN 19

class Device {
private:
    UltrasonicSensor _sensor;
    ServoValve       _valve;
    EventHandler     _eventHandler;
    Command          _command;
    unsigned long    _lastSendTime;

    void sendData(float level) {
        HTTPClient http;
        http.begin("https://httpbin.org/post");
        http.addHeader("Content-Type", "application/json");

        String body = "{\"waterLevel\":" + String(level) +
                      ",\"valveOpen\":" + String(_valve.isOpen()) + "}";

        http.POST(body);
        http.end();
    }

public:
    Device() : _sensor(TRIG_PIN, ECHO_PIN),
               _valve(SERVO_PIN),
               _eventHandler(&_valve),
               _command(&_valve),
               _lastSendTime(0) {}

    void setup() {
        Serial.begin(115200);
        Serial.println("================================");
        Serial.println("  AquaSense Tech - GreenWave Inc.");
        Serial.println("  Developer: Tu Nombre Apellido");
        Serial.println("================================");

        _sensor.begin();
        _valve.begin();

        WiFi.begin("Wokwi-GUEST", "");
        while (WiFi.status() != WL_CONNECTED) {
            delay(500);
            Serial.print(".");
        }
        Serial.println("WiFi connected!");
    }

    void loop() {
        float level = _sensor.read();
        _eventHandler.evaluate(level);

        unsigned long now = millis();
        if (now - _lastSendTime >= 5000) {
            sendData(level);
            _lastSendTime = now;
        }

        delay(1000);
    }
};
```

---

## 8. sketch.ino

```cpp
#include "Device.h"

Device device;

void setup() {
    device.setup();
}

void loop() {
    device.loop();
}
```

---

## 9. Errores más comunes (para no repetirlos)

| Error | Correcto |
|---|---|
| `class Hija :: public Padre` | `class Hija : public Padre` |
| `void read() overide` | `float read() override` |
| Métodos dentro del constructor | Métodos al mismo nivel que el constructor |
| Métodos dentro de otros métodos | Imposible en C++ |
| `_valve ->activate()` | `_valve->activate()` |
| `virtual` en `private` | `virtual` en `public` |
| `Serial.begin(15200)` | `Serial.begin(115200)` |
| `#include Sensor.h` | `#include "Sensor.h"` |

---

## 10. Punteros vs objetos directos

```cpp
ServoValve  _valve;    // objeto directo → usa .
ServoValve* _valve;    // puntero        → usa ->

_valve.activate();     // objeto directo
_valve->activate();    // puntero

EventHandler(&_valve)  // & convierte objeto en puntero para pasarlo
```

---

## 11. Pregunta 1 — Application Service Layer

| Servicio | Requisito | Interfaz |
|---|---|---|
| **Monitoreo de nivel de agua** | Recibir y mostrar nivel en tiempo real vía HTTP POST desde el ESP32. | Móvil (iOS/Android) — gauge o porcentaje. |
| **Estado de válvula** | Mostrar si la válvula está abierta o cerrada según umbrales 25%/95%. | Móvil — texto "ABIERTA" o "CERRADA". |
| **Notificaciones críticas** | Alertar cuando nivel < 25% o > 95%. | Móvil — push notification aunque la app esté cerrada. |
| **Control manual de válvula** | Forzar apertura/cierre independiente del sensor. | Móvil — switch ACTIVADO/DESACTIVADO. |

**Conclusión tipo:**
> La capa de servicio debe cubrir los servicios de monitoreo de nivel de agua, estado de la válvula, notificaciones críticas y control manual. La interfaz principal es **móvil** (iOS/Android) porque el usuario requiere acceso frecuente e inmediato desde cualquier lugar. En contexto industrial puede complementarse con un **dashboard web** para supervisión de múltiples tanques.

---

## 12. Checklist para el examen

- [ ] `sketch.ino` solo instancia `Device` y delega
- [ ] Clases abstractas con `= 0`
- [ ] Clases hijas con `: public Padre` y `override`
- [ ] Constructor inicializa atributos con `: attr(val)`
- [ ] `sendData()` en `private`, `setup()`/`loop()` en `public`
- [ ] Punteros usan `->`, objetos directos usan `.`
- [ ] `delay(1000)` siempre al final del `loop()`
- [ ] Title block con nombre, empresa y propósito en cada archivo
- [ ] Nombres en inglés, PascalCase para clases, camelCase para métodos
- [ ] Info de empresa impresa en `Serial` al inicio
