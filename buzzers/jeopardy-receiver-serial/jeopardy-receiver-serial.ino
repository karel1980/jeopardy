#include <esp_now.h>
#include <WiFi.h>

#include <ArduinoJson.h> // Library dependency : ArduinoJSON 7.2.0

uint8_t broadcastAddress[] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};
esp_now_peer_info_t peerInfo;

typedef struct struct_message {
    int playerId;
};
struct_message myData;

// callback function that will be executed when data is received
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

  // Send to serial
  Serial.println("received ESPNOW json message - passing it to serial");
  Serial.println(maybeJson);
}
 
void setup() {
  Serial.begin(115200);
  
  WiFi.mode(WIFI_STA);

  // Init ESP-NOW
  if (esp_now_init() != ESP_OK) {
    Serial.println("Error initializing ESP-NOW");
    return;
  }
  
  // Once ESPNow is successfully Init, we will register for recv CB to
  // get recv packer info
  esp_now_register_recv_cb(esp_now_recv_cb_t(OnDataRecv));
  
  // add peer
  memcpy(peerInfo.peer_addr, broadcastAddress, 6);
  peerInfo.channel = 0;  
  peerInfo.encrypt = false;
  if (esp_now_add_peer(&peerInfo) != ESP_OK){
    Serial.println("Failed to add peer");
    return;
  }

}
 
unsigned long nextHeartBeat = 0;

void loop() {
	if (millis() > nextHeartBeat) {
    Serial.println("HEARTBEAT");
    nextHeartBeat = millis() + 2000;
  }
  if (Serial.available() > 0) {
    // TODO: make this non blocking?
    Serial.println("reading until newline");
    String inputString = Serial.readStringUntil('\n');
    
    handleSerialInput(inputString);
  }
}

void handleSerialInput(String inputString) {
  // Check that it's json. If it's json, pass it along to the players
  StaticJsonDocument<512> doc;  
  if (deserializeJson(doc, inputString)) {
    Serial.println("could not deserialize document");
    return;
  }

  Serial.println("forwarding message to espnow");
  uint8_t* dataPtr = (uint8_t*)inputString.c_str();
  int dataLen = inputString.length();
  esp_now_send(broadcastAddress, dataPtr, dataLen);

}