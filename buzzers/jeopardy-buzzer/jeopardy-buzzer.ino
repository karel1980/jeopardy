#include <esp_now.h>
#include <WiFi.h>

#include <ArduinoJson.h> // Library dependency: ArduinoJson 7.2.0

#define PLAYER_ID 3

// #define LED_PIN 13
// #define BUTTON_PIN 12

// On one of the boards I missoldered the connector, so all the pins are wrong and the pin next to GND needs to act as GND
//#define GND_EXTRA_PIN 13
//#define LED_PIN 12
//#define BUTTON_PIN 14

// Backup board without led
# define BUTTON_PIN 26
# define LED_PIN 12


uint8_t broadcastAddress[] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};
esp_now_peer_info_t peerInfo;


int buttonState;            // the current reading from the input pin
int lastButtonState = LOW;  // the previous reading from the input pin

unsigned long lastDebounceTime = 0;  // the last time the output pin was toggled
unsigned long debounceDelay = 50;    // the debounce time; increase if the output flickers

unsigned long lastSent = 0;
unsigned long lastPressed = 0;

// Callback function to handle ESP-NOW send status
void OnDataSent(const uint8_t *mac_addr, esp_now_send_status_t status) {
  if (status == ESP_NOW_SEND_SUCCESS) {
    Serial.println("Message sent successfully");
  } else {
    Serial.println("Message send failed");
  }
}

void OnDataRecv(const uint8_t * mac, const uint8_t *incomingData, int len) {
  String maybeJson = "";
  for (int i = 0; i < len; i++) {
    maybeJson += (char)incomingData[i];
  }
  StaticJsonDocument<512> doc;  
  if (deserializeJson(doc, maybeJson)) {
    Serial.println("could not deserialize document");
    return;
  }

  // Serial.println("looks like valid json");

  if (doc.containsKey("enable")) {
    for (int i = 0; i < doc["enable"].size(); i++) {
      int enable = doc["enable"][i];
      if (enable == -1 || enable == PLAYER_ID) {
        Serial.println("enabling this button");
        digitalWrite(LED_PIN, HIGH);
      }
    }
  }
  if (doc.containsKey("disable")) {
    for (int i = 0; i < doc["disable"].size(); i++) {
      int disable = doc["disable"][i];
      if (disable == -1 || disable == PLAYER_ID) {
        Serial.println("disabling this button");
        digitalWrite(LED_PIN, LOW);
      }
    }
  }
}

void setup() {
  Serial.begin(115200);

  // ESPNOW stuff
  WiFi.mode(WIFI_STA);
  if (esp_now_init() != ESP_OK) {
    Serial.println("Error initializing ESP-NOW");
    return;
  }
  esp_now_register_send_cb(OnDataSent);
  esp_now_register_recv_cb(esp_now_recv_cb_t(OnDataRecv));
  
  memcpy(peerInfo.peer_addr, broadcastAddress, 6);
  peerInfo.channel = 0;  
  peerInfo.encrypt = false;
  if (esp_now_add_peer(&peerInfo) != ESP_OK){
    Serial.println("Failed to add peer");
    return;
  }
  Serial.println("ESP-NOW initialized and ready to send messages");


  // GPIO
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, HIGH); // Turn LED on just to test that it works
#ifdef GND_EXTRA_PIN
  pinMode(GND_EXTRA_PIN, OUTPUT);
  digitalWrite(GND_EXTRA_PIN, LOW);
#endif
}

unsigned long next_heartbeat = 0;
void loop() {
  if (millis() > next_heartbeat) {
    Serial.println("heartbeat");
    next_heartbeat = millis() + 2000;
  }
  int reading = digitalRead(BUTTON_PIN);

  if (reading != lastButtonState) {
    lastDebounceTime = millis();
  }

  if ((millis() - lastDebounceTime) > debounceDelay) {
    if (reading != buttonState) {
      buttonState = reading;
      if (buttonState == LOW) {
        send_message();
      }
    }
  }

  lastButtonState = reading;
}

void send_message() {
    DynamicJsonDocument doc(512);
    doc["buzzer"] = PLAYER_ID;
    String jsonString;
    serializeJson(doc, jsonString);
    Serial.println("sending buzzer message over espnow");
    Serial.println(jsonString);
    sendStringOverESPNOW(jsonString);
}

void sendStringOverESPNOW(String data) {
  uint8_t* dataPtr = (uint8_t*)data.c_str();
  int dataLen = data.length();
  
  esp_now_send(broadcastAddress, dataPtr, dataLen);
}