#include <esp_now.h>
#include <WiFi.h>

#include <ArduinoJson.h> // Library dependency: ArduinoJson 7.2.0

#define PLAYER_ID 1

uint8_t broadcastAddress[] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};
esp_now_peer_info_t peerInfo;

const int buttonPin = 26;

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

void setup() {
  Serial.begin(115200);

  // ESPNOW stuff
  WiFi.mode(WIFI_STA);
  if (esp_now_init() != ESP_OK) {
    Serial.println("Error initializing ESP-NOW");
    return;
  }
  esp_now_register_send_cb(OnDataSent);
  
  memcpy(peerInfo.peer_addr, broadcastAddress, 6);
  peerInfo.channel = 0;  
  peerInfo.encrypt = false;
  if (esp_now_add_peer(&peerInfo) != ESP_OK){
    Serial.println("Failed to add peer");
    return;
  }
  Serial.println("ESP-NOW initialized and ready to send messages");

  // Button stuff
  pinMode(buttonPin, INPUT_PULLUP);
}

void loop() {
  int reading = digitalRead(buttonPin);

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