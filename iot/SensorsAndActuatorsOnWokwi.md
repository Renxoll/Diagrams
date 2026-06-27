# Repaso Completo — IoT ModestIoT en Arduino C++
## Sensores y Actuadores practicados

---

## 1. Arquitectura general (siempre igual)

```
sketch.ino
    └── Device
            ├── [Sensor concreto]    (hereda Sensor)
            ├── [Actuador concreto]  (hereda Actuator)
            ├── EventHandler
            └── Command
```

**Regla clave:** `sketch.ino` solo instancia `Device` y delega. Nada más.

---

## 2. Clases abstractas (siempre iguales)

```cpp
// Sensor.h
class Sensor {
public:
    virtual void begin() = 0;
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

---

## 3. SENSORES

### 3.1 UltrasonicSensor — HC-SR04
**Devuelve:** distancia en cm, o nivel de agua en %
**Pines:** TRIG (OUTPUT), ECHO (INPUT)

```cpp
#include <Sensor.h>

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

    // Opción A: retorna distancia en cm
    float read() override {
        digitalWrite(_trigPin, LOW);
        delayMicroseconds(2);
        digitalWrite(_trigPin, HIGH);
        delayMicroseconds(10);
        digitalWrite(_trigPin, LOW);

        long tiempo_echo = pulseIn(_echoPin, HIGH);
        float distancia = tiempo_echo * 0.034 / 2;

        return constrain(distancia, 0.0, 400.0);
    }

    // Opción B: retorna nivel de agua en %
    // float nivel = ((ALTURA_TANQUE - distancia) / ALTURA_TANQUE) * 100.0;
    // return constrain(nivel, 0.0, 100.0);
};
```

**Fórmulas:**
```
distancia (cm) = tiempo_echo × 0.034 / 2
nivel (%)      = ((altura_tanque - distancia) / altura_tanque) × 100
```

**Conexiones diagram.json:**
```json
{ "type": "wokwi-hc-sr04", "id": "hcsr04", ... }

[ "esp:5",   "hcsr04:TRIG", "green", [] ],
[ "esp:18",  "hcsr04:ECHO", "blue",  [] ],
[ "esp:5V",  "hcsr04:VCC",  "red",   [] ],
[ "esp:GND", "hcsr04:GND",  "black", [] ]
```

---

### 3.2 DHTSensor — DHT22
**Devuelve:** temperatura en °C
**Pines:** un solo pin de datos
**Librería:** `#include <DHT.h>`

```cpp
#include <DHT.h>
#include "Sensor.h"

class DHTSensor : public Sensor {
private:
    int _pin;
    DHT _dht;

public:
    DHTSensor(int pin) : _pin(pin), _dht(pin, DHT22) {}

    void begin() override {
        _dht.begin();   // sin pinMode, la librería lo maneja
    }

    float read() override {
        return _dht.readTemperature();  // sin fórmulas
    }
};
```

**Conexiones diagram.json:**
```json
{ "type": "wokwi-dht22", "id": "dht1", ... }

[ "esp:4",   "dht1:SDA", "green", [] ],
[ "esp:5V",  "dht1:VCC", "red",   [] ],
[ "esp:GND", "dht1:GND", "black", [] ]
```

---

## 4. ACTUADORES

### 4.1 ServoValve — Servo motor
**Función:** controla válvula de bola (0° cerrada, 90° abierta)
**Librería:** `#include <ESP32Servo.h>`

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
        deactivate();       // arranca cerrado
    }

    void activate() override {
        _servo.write(90);   // 90° = abierto
        _isOpen = true;
    }

    void deactivate() override {
        _servo.write(0);    // 0° = cerrado
        _isOpen = false;
    }

    bool isOpen() { return _isOpen; }
};
```

**Conexiones diagram.json:**
```json
{ "type": "wokwi-servo", "id": "servo1", ... }

[ "esp:19",  "servo1:PWM", "orange", [] ],
[ "esp:5V",  "servo1:V+",  "red",    [] ],
[ "esp:GND", "servo1:GND", "black",  [] ]
```

---

### 4.2 LedIndicator — LED
**Función:** enciende o apaga un LED

```cpp
#include "Actuator.h"

class LedIndicator : public Actuator {
private:
    int _pin;
    bool _isOn;

public:
    LedIndicator(int pin) : _pin(pin), _isOn(false) {}

    void begin() override {
        pinMode(_pin, OUTPUT);
    }

    void activate() override {
        digitalWrite(_pin, HIGH);
        _isOn = true;
    }

    void deactivate() override {
        digitalWrite(_pin, LOW);
        _isOn = false;
    }

    bool isOn() { return _isOn; }
};
```

**Conexiones diagram.json:**
```json
{ "type": "wokwi-led", "id": "led1", "attrs": { "color": "red" } }

[ "esp:19",  "led1:A",   "red",   [] ],
[ "led1:C",  "esp:GND",  "black", [] ]
```

---

### 4.3 LCDDisplay — LCD 1602 I2C
**Función:** muestra mensajes en pantalla
**Librería:** `#include <LiquidCrystal_I2C.h>`

```cpp
#include <LiquidCrystal_I2C.h>
#include "Actuator.h"

class LCDDisplay : public Actuator {
private:
    LiquidCrystal_I2C _lcd;
    bool _isAlert;

public:
    LCDDisplay() : _lcd(0x27, 16, 2), _isAlert(false) {}

    void begin() override {
        _lcd.init();
        _lcd.backlight();
    }

    void activate() override {      // mostrar alerta
        _lcd.clear();
        _lcd.setCursor(0, 0);
        _lcd.print("ALERTA");
        _isAlert = true;
    }

    void deactivate() override {    // mostrar normal
        _lcd.clear();
        _lcd.setCursor(0, 0);
        _lcd.print("TEMPERATURA OK");
        _isAlert = false;
    }

    void display(String msg) {      // mostrar mensaje personalizado
        _lcd.clear();
        _lcd.setCursor(0, 0);
        _lcd.print(msg);
    }

    bool isAlert() { return _isAlert; }
};
```

**Conexiones diagram.json:**
```json
{ "type": "wokwi-lcd1602", "id": "lcd1", "attrs": { "pins": "i2c" } }

[ "lcd1:SDA", "esp:SDA",   "blue",   [] ],
[ "lcd1:SCL", "esp:SCL",   "yellow", [] ],
[ "lcd1:VCC", "esp:5V",    "red",    [] ],
[ "lcd1:GND", "esp:GND.2", "black",  [] ]
```

⚠️ **Importante:** el atributo `"pins": "i2c"` es obligatorio para activar SDA/SCL.

---

## 5. Patrones fijos que no cambian

### EventHandler.h
```cpp
#include "[Actuador].h"

class EventHandler {
private:
    [Actuador]* _[actuador];

public:
    EventHandler([Actuador]* actuador) : _[actuador](actuador) {}

    void evaluate(float valor) {
        if (valor < UMBRAL_BAJO) {
            _[actuador]->activate();
        } else if (valor > UMBRAL_ALTO) {
            _[actuador]->deactivate();
        }
    }
};
```

### Command.h
```cpp
#include "[Actuador].h"

class Command {
private:
    [Actuador]* _[actuador];

public:
    Command([Actuador]* actuador) : _[actuador](actuador) {}

    void execute(String cmd) {
        if (cmd == "ON")  _[actuador]->activate();
        if (cmd == "OFF") _[actuador]->deactivate();
    }
};
```

### Device.h
```cpp
class Device {
private:
    [Sensor]      _sensor;
    [Actuador]    _actuador;
    EventHandler  _eventHandler;
    Command       _command;
    unsigned long _lastSendTime;

    void sendData(float valor) {
        HTTPClient http;
        http.begin("https://httpbin.org/post");
        http.addHeader("Content-Type", "application/json");
        String body = "{\"value\":" + String(valor) + "}";
        http.POST(body);
        http.end();
    }

public:
    Device() : _sensor(/* pines */),
               _actuador(/* pin */),
               _eventHandler(&_actuador),
               _command(&_actuador),
               _lastSendTime(0) {}

    void setup() {
        Serial.begin(115200);
        Serial.println("== Empresa - Developer ==");
        _sensor.begin();
        _actuador.begin();
        WiFi.begin("Wokwi-GUEST", "");
        while (WiFi.status() != WL_CONNECTED) { delay(500); }
        Serial.println("WiFi connected!");
    }

    void loop() {
        float valor = _sensor.read();
        _eventHandler.evaluate(valor);
        unsigned long now = millis();
        if (now - _lastSendTime >= 5000) {
            sendData(valor);
            _lastSendTime = now;
        }
        delay(1000);
    }
};
```

### sketch.ino (siempre igual)
```cpp
#include "Device.h"

Device device;

void setup() { device.setup(); }
void loop()  { device.loop();  }
```

---

## 6. Errores más comunes

| Error | Correcto |
|---|---|
| `class Hija :: public Padre` | `class Hija : public Padre` |
| `void read() overide` | `float read() override` |
| Métodos dentro de otros métodos | Imposible en C++ |
| `_valve ->activate()` | `_valve->activate()` |
| `virtual` en `private` | `virtual` en `public` |
| `Serial.begin(15200)` | `Serial.begin(115200)` |
| `#include Sensor.h` | `#include "Sensor.h"` |
| `}` al cerrar clase | `};` |
| `;` después de `}` de método | sin `;` |
| `string` | `String` (mayúscula en Arduino) |
| LCD sin `"pins": "i2c"` | `"attrs": { "pins": "i2c" }` |

---

## 7. Tabla resumen de casos practicados

| Caso | Sensor | Actuador | Umbral bajo | Umbral alto |
|---|---|---|---|---|
| AquaSense | HC-SR04 → nivel % | ServoValve | 25% → abrir | 95% → cerrar |
| SmartParking | HC-SR04 → distancia cm | LedIndicator | < 10cm → ON | > 50cm → OFF |
| SmartClimate | DHT22 → temp °C | LCDDisplay | < 10°C → frio | > 35°C → calor |

---

## 8. Checklist para el examen

- [ ] `sketch.ino` solo instancia `Device` y delega
- [ ] Clases abstractas con `= 0` en `public`
- [ ] Clases hijas con `: public Padre` y `override`
- [ ] Constructor inicializa con `: attr(val), attr2(val2)`
- [ ] `sendData()` en `private`, `setup()`/`loop()` en `public`
- [ ] Punteros usan `->`, objetos directos usan `.`
- [ ] `delay(1000)` siempre al final del `loop()`
- [ ] Title block con nombre, empresa y propósito en cada archivo
- [ ] Nombres en inglés, PascalCase clases, camelCase métodos
- [ ] Info de empresa en `Serial` al inicio de `setup()`
- [ ] LCD con atributo `"pins": "i2c"` en diagram.json
- [ ] `};` siempre al cerrar una clase
