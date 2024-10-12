#include <Servo.h>
#include <SoftwareSerial.h>

// Create Servo objects for each motor
Servo lateralServo;
Servo eyeVerticalServo;
Servo eyeHorizontalServo;
Servo noddingServo;
Servo jawServo;

// RGB LED pins
const int redPin = 4;
const int greenPin = 7;
const int bluePin = 8;

// Bluetooth module connection
SoftwareSerial bluetooth(11, 2); // RX, TX

String inputString = "";
bool stringComplete = false;
bool UnderRaspberryPi = false;

void setup() {
  // Attach the servos to their respective pins
  lateralServo.attach(3);
  eyeVerticalServo.attach(5);
  noddingServo.attach(6);
  eyeHorizontalServo.attach(9);
  jawServo.attach(10);
  
  // Set up RGB LED pins
  pinMode(redPin, OUTPUT);
  pinMode(greenPin, OUTPUT);
  pinMode(bluePin, OUTPUT);
  
  // Start serial communication
  Serial.begin(9600);
  bluetooth.begin(9600);

  inputString.reserve(200);

  Serial.println("Robot Head Control Ready");
  resetServos();
  setRGBColor(0, 255, 0); // Set initial color to green
}

void loop() {
  while (bluetooth.available()) {
    char inChar = (char)bluetooth.read();
    inputString += inChar;
    if (inChar == '\n') {
      stringComplete = true;
    }
  }

  if (stringComplete) {
    parseInput(inputString);
    inputString = "";
    stringComplete = false;
  }
}

void parseInput(String input) {
  input.trim();
  
  if (input == "TOGGLE_CONTROL") {
    UnderRaspberryPi = !UnderRaspberryPi;
    String response = UnderRaspberryPi ? "RaspberryPi Control ON" : "App Control ON";
    Serial.println(response);
    setRGBColor(UnderRaspberryPi ? 255 : 0, UnderRaspberryPi ? 0 : 255, 0);
    return;
  }

  if (input == "RESET") {
    resetServos();
    Serial.println("Servos Reset");
    return;
  }

  int commaIndex = input.indexOf(',');

  if (commaIndex != -1) {
    String command = input.substring(0, commaIndex);
    String angleStr = input.substring(commaIndex + 1);
    int angle = angleStr.toInt();

    switch (command[0]) {
      case 'L':
        lateralServo.write(angle);
        Serial.println("Lateral motion: " + String(angle));
        break;
      case 'V':
        eyeVerticalServo.write(angle);
        Serial.println("Eye Vertical motion: " + String(angle));
        break;
      case 'H':
        eyeHorizontalServo.write(angle);
        Serial.println("Eye Horizontal motion: " + String(angle));
        break;
      case 'N':
        noddingServo.write(angle);
        Serial.println("Nodding motion: " + String(angle));
        break;
      case 'J':
        jawServo.write(angle);
        Serial.println("Jaw motion: " + String(angle));
        break;
      case 'R':
        if (command == "RGB") {
          // Expect RGB values in the format "RGB,R,G,B"
          int secondComma = angleStr.indexOf(',');
          int thirdComma = angleStr.indexOf(',', secondComma + 1);
          if (secondComma != -1 && thirdComma != -1) {
            int r = angleStr.substring(0, secondComma).toInt();
            int g = angleStr.substring(secondComma + 1, thirdComma).toInt();
            int b = angleStr.substring(thirdComma + 1).toInt();
            setRGBColor(r, g, b);
            Serial.println("RGB color set to: " + String(r) + "," + String(g) + "," + String(b));
          }
        }
        break;
      default:
        Serial.println("Unknown command: " + command);
    }
  } else {
    Serial.println("Invalid input format: " + input);
  }
}

void resetServos() {
  lateralServo.write(90);
  eyeVerticalServo.write(90);
  eyeHorizontalServo.write(90);
  noddingServo.write(90);
  jawServo.write(90);
  Serial.println("All servos reset to 90 degrees");
}

void setRGBColor(int red, int green, int blue) {
  analogWrite(redPin, red);
  analogWrite(greenPin, green);
  analogWrite(bluePin, blue);
}