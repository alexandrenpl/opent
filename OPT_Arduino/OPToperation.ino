// CHECK EXPOSURE_TIME_ms
// CHECK MS1, MS2 AND MS3
// CHECK onelap_


#define DIR_PIN 2
#define STEP_PIN 3
#define MS1 5
#define MS2 6
#define MS3 7
#define slp 8
#define onelap_ 1600
#define TRIG_PIN_IN 13
#define ENABLE_Motor 12
#define LED_A 40 // A&B are the Green LED
#define LED_B 41
#define LED_C 42 // C&D are the Blue LED
#define LED_D 43

int LED_1 = LED_C;
int LED_2 = LED_D;

int EXPOSURE_TIME_ms = 600; // Higher than Exposure time and autoexposure upper limit (SpinView)

int timeA = millis();
boolean acquisition = true;
boolean oneLap = true;
int step_i = 1;

void setup() {
  Serial.begin(9600);
  pinMode(DIR_PIN, OUTPUT);
  pinMode(STEP_PIN, OUTPUT);
  pinMode(TRIG_PIN_IN, OUTPUT);
  pinMode(ENABLE_Motor, OUTPUT);
  pinMode(MS1, OUTPUT);
  pinMode(MS2, OUTPUT);
  pinMode(MS3, OUTPUT);
  // (400-steps stepper motor)
  digitalWrite(MS1, LOW);
  digitalWrite(MS2, HIGH);
  digitalWrite(MS3, LOW);
  digitalWrite(ENABLE_Motor, HIGH);
  //digitalWrite(slp,LOW);

  // LED Control

  pinMode(LED_1, OUTPUT);
  pinMode(LED_2, OUTPUT);  

}

void loop() {

  // read the sensor:
  if (Serial.available() > 0) {
    int inByte = Serial.read();
    // do something different depending on the character received.
    // The switch statement expects single number values for each case;
    // in this exmaple, though, you're using single quotes to tell
    // the controller to get the ASCII value for the character.  For
    // example 'a' = 97, 'b' = 98, and so forth:

    switch (inByte) {
      case 'a':    // Acquisition
        acquire();
        break;
      case 'b':    // b 45 deg and stop; bb  rotate 90 deg; bbbb rotate 180 deg; bbbbbbbb rotate 360 deg
        rotater();
        break;
      case 'c':    // c infinite loop
        infiniteloop();
        break;
      case 'd':    // (Rotate 180 deg and stop for 5 seconds) loop
        rotate180();
        break;
      default:
        break;
    }
  }
}

void acquire() {
    digitalWrite(ENABLE_Motor, LOW);
  do {
    //if (!acquisition && (millis() >= timeA + 10000) && (millis() <= timeA + 10010)) {
    //  acquisition = true;
    //}


    //rotate a specific number of microsteps per run (microsteps/step, speed from 0.01 to 1 - fastest))

    if (acquisition && oneLap) {

      digitalWrite(LED_1, HIGH);
      digitalWrite(LED_2, HIGH);
      
      digitalWrite(TRIG_PIN_IN, HIGH);  //trigger camera and wait the specified "delay" ms for acquisition
      delay(2);  //500ms check with camera preview how much time is necessary for finishing acquiring 1 image!
      digitalWrite(TRIG_PIN_IN, LOW);  //turn off camera trigger and wait before stepping again
      
      delay(EXPOSURE_TIME_ms); 

      digitalWrite(LED_1, LOW);
      digitalWrite(LED_2, LOW);
      delay(400); //200ms  time to transfer file to PC


      step_i = rotate(1, step_i);  //enter number of microsteps (total revolution = 3200 microsteps!) per step here: for 400 steps enter 8, for 800 enter 4, for 1600 enter 2
      //negative values of microsteps will rotate CW
      //200ms before triggering camera

      Serial.println(step_i-1);
    }

    if (step_i > onelap_) {
      oneLap = false;
      
    }
      } while (oneLap);
  step_i = 1;
  oneLap = true;
  digitalWrite(ENABLE_Motor, HIGH);
  return;
}

void infiniteloop() {
  digitalWrite(ENABLE_Motor, LOW);
  do {
    digitalWrite(STEP_PIN, HIGH);
    delay(1);

    digitalWrite(STEP_PIN, LOW);
    delay(5);
  }while (1 == 1);
}

void rotater(){
    digitalWrite(ENABLE_Motor, LOW);
    rotate(onelap_/8,0);
    digitalWrite(ENABLE_Motor, HIGH);
}

void rotate180(){
    digitalWrite(ENABLE_Motor, LOW);
  do {
    rotate(onelap_/2,0);
    digitalWrite(ENABLE_Motor, HIGH);
    delay(5000);
    digitalWrite(ENABLE_Motor, LOW);
  }while (1 == 1);
  
}

int rotate(int steps, int step_i) {

  int dir = (steps > 0) ? HIGH : LOW;
  steps = abs(steps);
  digitalWrite(DIR_PIN, dir);
  int i;
  for (i = 0; i < steps; i++) {
    digitalWrite(STEP_PIN, HIGH);
    delay(1);

    digitalWrite(STEP_PIN, LOW);
    delay(1);
  }
  return step_i + i;
}
