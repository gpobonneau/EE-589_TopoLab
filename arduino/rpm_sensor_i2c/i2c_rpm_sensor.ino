// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ################ INCLUDE #################
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#include <Wire.h>

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ############ HARDWARE SETUP ##############
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#define MAX_RPM         50000
#define NB_POLES        17
#define RPM_SENSOR_PIN  9
#define SLAVE_ADDR      9
#define ANSWERSIZE      5       // in bytes (long int is 4 bytes)
#define DELAY           50      // loop time delay in ms

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ########### DECLARE VARIABLES ############
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

String input_sequence = "";
volatile float raw_rpm_value = 0;
bool flag_verbose = false;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ################## MAIN ##################
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

void setup() {
  // INITIALISATION
  Serial.begin(57600);
  Serial.setTimeout(3);
  delay(500);
  Serial.println("Booting...");

  // SETUP INTERRUPTS
  Serial.println("Enabling interrupts");
  attachInterrupt(RPM_SENSOR_PIN, ext_rising, RISING);

  // SETUP I2C communication
  Wire.begin(SLAVE_ADDR);
  Wire.onRequest(requestEvent);
  Wire.onReceive(receiveEvent);

  Serial.flush();
  Serial.println("Ready !");
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

void loop() {

  // READ SERIAL
  if (Serial.available() > 0 ) {
    
    input_sequence = Serial.readString();
    
    switch (input_sequence[0]) {
      case 'V' :
      case 'v' :
        flag_verbose = !flag_verbose;
        Serial.println("Toggle Verbose;");
        break;
      default :
        flag_verbose = false;
        break;
    }     
    Serial.flush();
  }

  if (flag_verbose) {
    Serial.print(raw_rpm_value);
    Serial.println(";");
  }

  delay(DELAY);
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ############### FUNCTIONS ################
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

void ext_rising() { // external interupt function to measure RPM signal frequency
  
  static long int prev_time = 0;
  static long int current_time = 0;

  current_time = micros();
  
  raw_rpm_value = 1000000.f/(current_time - prev_time);
  prev_time = current_time;  
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

void receiveEvent() {

  if (flag_verbose) {
    Serial.println("Receive event");
  }
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

void requestEvent() {

//  static unsigned long int response;
  byte response[ANSWERSIZE];
  static unsigned int rpm = 0; // 2 byte of 16 bits
  
  rpm = round(map(raw_rpm_value*NB_POLES/2, 0, MAX_RPM, 0, 2^16-1));

  // Format answer as array until better solution
  for (byte i=0; i<ANSWERSIZE; i++) {
    response[i] = (byte) String(rpm, DEC).charAt(i);
  }
  
  Wire.write(response, sizeof(response));

  if (flag_verbose) {
    Serial.println("Request event");  
  }
}
 
