#include <Servo.h>

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

String inputString = "";
bool stringComplete = false;
bool UnderRaspberryPi = true; // Set to true by default
bool isTalking = false;
bool isThinking = false;

// Smooth motion parameters
const unsigned long MOVE_INTERVAL = 20; // milliseconds between each step
const float EASING_FACTOR = 0.1; // Adjust this for smoother or more responsive motion

// Jaw movement parameters
int targetJawAngle = 90;
float currentJawAngle = 90;

// Thinking motion parameters
int targetLateralAngle = 90;
float currentLateralAngle = 90;
bool thinkingDirectionRight = true;

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

  inputString.reserve(200);

  Serial.println("Robot Head Control Ready");
  resetServos();
  setRGBColor(255, 0, 0); // Set initial color to red to indicate Raspberry Pi control
}

void loop() {
  while (Serial.available()) {
    char inChar = (char)Serial.read();
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

  static unsigned long lastMoveTime = 0;
  unsigned long currentTime = millis();
  
  if (currentTime - lastMoveTime >= MOVE_INTERVAL) {
    if (isTalking) {
      moveJaw();
    }

    if (isThinking) {
      thinkingMotion();
    }
    
    lastMoveTime = currentTime;
  }
}

void parseInput(String input) {
  input.trim();
  
  if (input == "TOGGLE_CONTROL") {
    UnderRaspberryPi = !UnderRaspberryPi;
    String response = UnderRaspberryPi ? "RaspberryPi Control ON" : "App Control ON";
    Serial.println(response);
    setRGBColor(UnderRaspberryPi ? 255 : 0, 0, 0); // Red when under Raspberry Pi control, off otherwise
    return;
  }

  if (input == "RESET") {
    resetServos();
    Serial.println("Servos Reset");
    return;
  }

  if (input == "U,1") {
    setRGBColor(0, 255, 0); // Green LED
    Serial.println("U,1 - Green LED On");
    return;
  }

  if (input == "U,0") {
    setRGBColor(0, 0, 0); // Turn off LED
    isThinking = true; // Start thinking motion
    Serial.println("U,0 - Green LED Off, Thinking motion started");
    return;
  }

  if (input == "T,1") {
    isTalking = true;
    isThinking = false; // Stop thinking motion
    setRGBColor(0, 0, 255); // Blue LED
    Serial.println("T,1 - Started talking, Blue LED On, Thinking motion stopped");
    return;
  }

  if (input == "T,0") {
    isTalking = false;
    setRGBColor(0, 0, 0); // Turn off LED
    Serial.println("T,0 - Stopped talking, LED Off");
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
  currentJawAngle = 90;
  currentLateralAngle = 90;
  Serial.println("All servos reset to 90 degrees");
}

void setRGBColor(int red, int green, int blue) {
  analogWrite(redPin, red);
  analogWrite(greenPin, green);
  analogWrite(bluePin, blue);
}

void moveJaw() {
  if (targetJawAngle >= 120 || targetJawAngle <= 20) {
    targetJawAngle = (targetJawAngle >= 120) ? 20 : 120;
  }
  
  currentJawAngle += (targetJawAngle - currentJawAngle) * EASING_FACTOR;
  jawServo.write(round(currentJawAngle));
  
  if (abs(targetJawAngle - currentJawAngle) < 1) {
    targetJawAngle = (targetJawAngle == 120) ? 20 : 120;
  }
}

void thinkingMotion() {
  if (thinkingDirectionRight) {
    targetLateralAngle = 125;
  } else {
    targetLateralAngle = 55;
  }
  
  currentLateralAngle += (targetLateralAngle - currentLateralAngle) * EASING_FACTOR;
  lateralServo.write(round(currentLateralAngle));
  
  if (abs(targetLateralAngle - currentLateralAngle) < 1) {
    thinkingDirectionRight = !thinkingDirectionRight;
  }
}