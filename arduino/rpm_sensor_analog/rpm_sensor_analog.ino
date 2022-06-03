// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ################ INCLUDE #################
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#include <Servo.h>

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ############ HARDWARE SETUP ##############
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#define PIN_RPM_IN    9
#define PIN_ESC_OUT   10
#define PIN_RPM_OUT   DAC1

#define MIN_DUTY  1000   // min pulse length in um
#define MAX_DUTY  2000   // max pulse length in um

#define MAX_RPM         1750    // true rpm given by MAX_RPM*NB_POLES/2
#define RES_DAC         12      // max res for DUE is 12bit
#define MAX_DAC         4095   // 2^RES_DAC - 1
#define NB_POLES        17      // number of electric poles in motor
#define DELAY           50      // loop time delay in ms

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ########### DECLARE VARIABLES ############
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Servo esc;

String input_sequence = "";
bool flag_verbose = false;

volatile unsigned int rpm_analog = 0;
volatile float rpm_raw = 0;
volatile int test = 0;

volatile float motor_throttle = 100;  // range 0-100%
volatile float duty_cycle = 2000;     //

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ################## MAIN ##################
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

void setup() {
  // INITIALISATION
  Serial.begin(57600);
  Serial.setTimeout(3);
  delay(500);
  Serial.println("Booting...");

  // TRUE DAC CONFIGUATION
  pinMode(PIN_RPM_OUT, OUTPUT);

  // SETUP INTERRUPTS
  Serial.println("Enabling interrupts");
  attachInterrupt(PIN_RPM_IN, int0_rpm_in, RISING);

  // CONFIGURE ESC
  Serial.println("Attaching ESC");
  esc.attach(PIN_ESC_OUT, MIN_DUTY, MAX_DUTY); // (pin, min pulse width, max pulse width in microseconds)
  motor_throttle = set_motor_throttle(motor_throttle);
  
  Serial.flush();
  Serial.println("Ready !");
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

void loop() {

  // READ SERIAL
  if (Serial.available() > 0 ) {
    
    input_sequence = Serial.readString();
    
    switch (input_sequence[0]) {
      case 'V' : // verbose toggle
      case 'v' :
        flag_verbose = !flag_verbose;
        Serial.println("Toggle Verbose;");
        break;
      case 'T' : // test variable
      case 't' :
        input_sequence.remove(0,1);
        test = input_sequence.toInt();
        break;
      case 'M' : // motor command
      case 'm' :
        input_sequence.remove(0,1);
        motor_throttle = set_motor_throttle(input_sequence.toInt());
        break;
      default :
        motor_throttle = set_motor_throttle(0);
        break;
    }     

    Serial.flush();
  }

  if (flag_verbose) {
    Serial.print(rpm_raw); //rpm_raw
    Serial.print(", \t");
    Serial.print(rpm_analog);
    Serial.print(", \t");
    Serial.print(motor_throttle);
    Serial.println(";");
  }

  // Write rpm value to pin
  analogWriteResolution(RES_DAC);
  analogWrite(PIN_RPM_OUT, rpm_analog);

  delay(DELAY);
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ############### FUNCTIONS ################
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

float set_motor_throttle(float throttle) { // sets motor speed
  
  if (throttle > 100) {
    throttle = 100;
  } else if (throttle < 0) {
    throttle = 0;
  }
  
  duty_cycle = map(throttle, 0, 100, MIN_DUTY, MAX_DUTY);  
  esc.writeMicroseconds(duty_cycle);

  return throttle;
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

void int0_rpm_in() { // external interrupt function to measure RPM signal frequencyitp
  
  static long int time_prev = 0; // previous interrupt time
  static long int time_curr = 0; // current time

  time_curr = micros();
  
  rpm_raw = 1000000.f/(time_curr - time_prev);
  time_prev = time_curr;  

  // safety bounds
  if (rpm_raw > MAX_RPM) {
    rpm_raw = MAX_RPM;
  } else if (rpm_raw < 0) {
    rpm_raw = 0;
  }
  
  // compute value to send to analog pin
  rpm_analog = (unsigned int) round(rpm_raw*MAX_DAC/MAX_RPM);
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 
