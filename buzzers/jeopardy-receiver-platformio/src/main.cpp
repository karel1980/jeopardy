#include <Arduino.h>

#include <Adafruit_GFX.h>    // Core graphics library
#include <SPI.h>

// display
#include "Adafruit_ST7789_Fri3d2024.h" // Hardware-specific library for GC9307 (ST7789) driver of Fri3d badge 2024
#include <Fonts/FreeSans18pt7b.h>

// espnow
#include <esp_now.h>
#include <WiFi.h>

#include <ArduinoJson.h> // Library dependency : ArduinoJSON 7.2.0


// Explicitly use hardware SPI port, default is software which is too slow
SPIClass *spi = new SPIClass(HSPI);
Adafruit_GFX_Fri3dBadge2024_TFT tft(spi, TFT_CS, TFT_DC, TFT_RST);

uint8_t broadcastAddress[] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};
esp_now_peer_info_t peerInfo;

void showCentered(String text) {
  short x;
  short y;
  unsigned short w;
  unsigned short h;

  tft.setTextColor(TFT_WHITE);
  tft.setFont(&FreeSans18pt7b);

  tft.setTextSize(1);
  tft.getTextBounds(text, 0, 0, &x, &y, &w, &h);

  tft.fillScreen(TFT_BLACK);
  tft.drawRect(0, 0, tft.width(), tft.height(), TFT_BLUE);
  tft.setCursor(tft.width() / 2 - w/2, tft.height()/2-h/2);
  tft.setTextColor(TFT_WHITE);
  tft.println(text);
}

void OnDataRecv(const uint8_t * mac, const uint8_t *incomingData, int len) {
  String maybeJson = "";
  for (int i = 0; i < len; i++) {
    maybeJson += (char)incomingData[i];
  }
  JsonDocument doc;  
  if (deserializeJson(doc, maybeJson)) {
    Serial.println("could not deserialize document");
    return;
  }

  // Send to serial
  Serial.println("received ESPNOW json message - passing it to serial");
  Serial.println(maybeJson);
}


void setupEspNow() {
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

void setup(void) {
  Serial.begin(115200);
  delay(3000); 
  Serial.println("Hello world - Adafruit GFX GC9307/ST7789 Fri3d badge");

  spi->begin(TFT_SCLK, TFT_MISO, TFT_MOSI, TFT_CS);
  tft.setSPISpeed(SPI_FREQUENCY);

  tft.init(TFT_WIDTH, TFT_HEIGHT);
  tft.setRotation( 3 );

  // Anything from the Adafruit GFX library can go here, see
  // https://learn.adafruit.com/adafruit-gfx-graphics-library
  
  showCentered("Jeopardy!");

  setupEspNow();
  delay(2000);
}


void handleSerialInput(String inputString) {
  // Check that it's json. If it's json, pass it along to the players
  JsonDocument doc;  
  if (deserializeJson(doc, inputString)) {
    Serial.println("could not deserialize document");
    return;
  }

  // If message contains 'display', show the value on screen
  if (doc["display"].is<String>()) {
    String display = doc["display"];
    showCentered(display);
  }

  Serial.println("forwarding message to espnow");
  uint8_t* dataPtr = (uint8_t*)inputString.c_str();
  int dataLen = inputString.length();
  esp_now_send(broadcastAddress, dataPtr, dataLen);
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


