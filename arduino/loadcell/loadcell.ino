// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ################ INCLUDE #################
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

//#include <Arduino.h>
#include <Servo.h>
#include "HX711.h"

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ############ HARDWARE SETUP ##############
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#define LOADCELL_SCK_PIN_1 5
#define LOADCELL_SCK_PIN_2 6
#define LOADCELL_SCK_PIN_3 7

#define LOADCELL_DOUT_PIN_1 2
#define LOADCELL_DOUT_PIN_2 3
#define LOADCELL_DOUT_PIN_3 4

#define CALIBRATION_1 2280.f
#define CALIBRATION_2 2280.f
#define CALIBRATION_3 2280.f

#define ESC_CTRL_PIN 10
#define RPM_SENSOR_PIN 9

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#define MIN_DUTY 1000   // min pulse length in um
#define MAX_DUTY 2000   // max pulse length in um
#define SLOWRATE 15     // signal slowed @X rate 
#define TE 10           // sampling time in ms

#define NB_POLES 17     // nb of electrical poles of motor

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ########### DECLARE VARIABLES ############
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Servo esc;

HX711 scale1;
HX711 scale2;
HX711 scale3;

String input_sequence = "";
int i = 0;

volatile float raw_rpm_value = 0;
volatile float motor_speed = 100;
volatile float duty_cycle = 2000;

bool flag_verbose = true;
bool flag_auto = false;
bool flag_ramp = false;
bool flag_prbs = false;

bool reset_flag_auto = true;
bool reset_flag_ramp = true;

float reading1 = 0;
float reading2 = 0;
float reading3 = 0;

float auto_motor_speed_target = 0;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ################## MAIN ##################
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

void setup() {
  // INITIALISATION
  Serial.begin(57600);
  Serial.setTimeout(3);
  delay(500);
  Serial.println("Booting...");

  // SETUP LOADCELLS
//  init_loadcells();

  // SETUP INTERRUPTS
  Serial.println("Enabling interrupts");
  attachInterrupt(RPM_SENSOR_PIN, ext_rising, RISING);

  // CONFIGURE ESC
  Serial.println("Attaching ESC");
  esc.attach(ESC_CTRL_PIN, MIN_DUTY, MAX_DUTY); // (pin, min pulse width, max pulse width in microseconds)
  motor_speed = set_motor_speed(motor_speed);

  Serial.flush();
  Serial.println("Ready !");
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

void loop() {

  // LOAD CELL
//  read_loadcells();

  // MOTOR CONTROL
  if (Serial.available() > 0 ) {

    i=0;
    reset_flag_ramp = true;
    reset_flag_auto = true;
    
    input_sequence = Serial.readString();
    
    switch (input_sequence[0]) {
      case 'v' :
        flag_verbose = !flag_verbose;
        Serial.println("Toggle Verbose;");
        break;
      case 'p' :
        flag_prbs = true;
        flag_auto = false;
        flag_ramp = false;
//        Serial.println("Toggle PRBS signal;");
        break;
      case 'r' :
        flag_ramp = true;
        flag_auto = false;
        flag_prbs = false;
        input_sequence.remove(0,1);
        auto_motor_speed_target = input_sequence.toInt();
//        Serial.println("Semi-auto ramp;");
//        Serial.println(auto_motor_speed_target);
        break;
      case 'a' :
        motor_speed = 0;
        flag_auto = true;
        flag_ramp = false;
        flag_prbs = false;
        input_sequence.remove(0,1);
        auto_motor_speed_target = input_sequence.toInt();
//        Serial.println("Auto advance;");
//        Serial.println(auto_motor_speed_target);
        break;
      case '0' :
      case '1' : 
      case '2' : 
      case '3' : 
      case '4' : 
      case '5' : 
      case '6' : 
      case '7' : 
      case '8' : 
      case '9' : 
        flag_auto = false;
        flag_ramp = false;
        flag_prbs = false;
        motor_speed = input_sequence.toInt();
        break;
      default :
        motor_speed = 0;
        flag_auto = false;
        flag_ramp = false;
        flag_prbs = false;
        break;
    }

    motor_speed = set_motor_speed(motor_speed);
     
    Serial.flush();
  } 

  // make commande signal slower than acquisition rate
  if (i<SLOWRATE-1) { 
    i+=1;
  } else {
    // AUTO ADVANCE
    if (flag_auto) {
      auto_ramp(auto_motor_speed_target);
    }
    
    // SEMI AUTO ADVANCE (RAMP)
    if (flag_ramp) {
      ramp(auto_motor_speed_target);
    }
    
    // SEMI AUTO ADVANCE (RAMP)
    if (flag_prbs) {
      prbs_signal();
    }
    
    i=0;
  }

  // COMMUNICATION
  if (flag_verbose) {
    Serial.print("Timestap : ");
    Serial.println(millis());
    Serial.print("PWM motor command = ");
    Serial.print(duty_cycle);
    Serial.println(" %");
    Serial.print("rpm_value = ");
    Serial.println(raw_rpm_value);
    Serial.print("HX711 TRUST: ");
    Serial.println(-reading1);
    Serial.print("HX711 TORQUE: ");
    Serial.println(reading2 - reading3 - (reading2+reading3)/2);
    Serial.println();
  } else {
    Serial.print(millis());
    Serial.print(",");
    Serial.print(duty_cycle);
    Serial.print(",");
    Serial.print(raw_rpm_value);
    Serial.println(";");
  }
  
  delay(TE);
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ############### FUNCTIONS ################
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

float set_motor_speed(float speed_percentage) {
  
  if (speed_percentage > 100) {
    speed_percentage = 100;
  } else if (speed_percentage < 0) {
    speed_percentage = 0;
  }
  
  duty_cycle = map(speed_percentage, 0, 100, MIN_DUTY, MAX_DUTY);  
  esc.writeMicroseconds(duty_cycle);

  return speed_percentage;
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

void auto_ramp(float target) {

//  static int k = 10;
//  static int l = 15;
//  
//  if (reset_flag_auto) {
//    k = 10;
//    l = 15;
//    reset_flag_auto = false;
//    reset_flag_ramp = true;
//  }
//
//  if (l>=15) {
//    ramp(k);
//  }
//
//  if (reset_flag_ramp) {
//    ramp(k);
//    k += 5;
//    l = 0;
//  }
//
//  l=+1;
//
//  if (k > target) {
//    reset_flag_auto = true;
//    flag_auto = false;
//  } 

}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

void ramp(float target) {
  
  static int i = 4;
  static int j = 0;
  
  if (reset_flag_ramp) {
    i = 4;
    j = 0;
    reset_flag_ramp = false;
  }
  
  motor_speed = motor_speed+2.5; // 2.5% points increments
  
//  if (motor_speed == target) {
//    if (j < 25) { // hold target speed for 5 seconds
//      i -= 1;
//      j += 1;
//    }
//  }
  
  if (motor_speed >= target) {
    flag_ramp = false;
    reset_flag_ramp = true;
//    motor_speed = 0;
  }
  
  motor_speed = set_motor_speed(motor_speed);
  i += 1;
  
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

void prbs_signal() {

  static uint16_t prbs11 = 0x7D0;
  static int newbit = 0;
  static int i = 0;

  newbit = (((prbs11 >> 10) ^ (prbs11 >> 8)) & 1);
  prbs11 = ((prbs11 << 1) | newbit) & 0x7FF;
  
  if (newbit) {
  motor_speed = 30;
  } else {
  motor_speed = 40;
  }
  
  motor_speed = set_motor_speed(motor_speed);
  i = 0;
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

void read_loadcells() {
  
  if (scale1.is_ready()) { // Thrust
    reading1 = scale1.get_units();
  } else {
    Serial.println("HX711-1 not found.");
  }
  
  if (scale2.is_ready()) { // Torque +
    reading2 = scale2.get_units();
  } else {
    Serial.println("HX711-2 not found.");
  }

  if (scale3.is_ready()) { // Torque -
    reading3 = scale3.get_units();
  } else {
    Serial.println("HX711-3 not found.");
  }
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

void init_loadcells() {
  
  Serial.println("Initializing the load cells");
  
  scale1.begin(LOADCELL_DOUT_PIN_1, LOADCELL_SCK_PIN_1);
  scale2.begin(LOADCELL_DOUT_PIN_2, LOADCELL_SCK_PIN_2);
  scale3.begin(LOADCELL_DOUT_PIN_3, LOADCELL_SCK_PIN_3);

  // set load cells
  scale1.set_scale(CALIBRATION_1);    // this value is obtained by calibrating the scale with known weights; see the README for details
  scale1.tare();               // reset the scale to 0

  scale2.set_scale(CALIBRATION_2);
  scale2.tare(); 

  scale3.set_scale(CALIBRATION_3);
  scale3.tare(); 
  
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

void ext_rising() {
  
  static long int prev_time = 0;
  static long int now_time = 0;

  now_time = micros();
  raw_rpm_value = 1000000.f/(now_time - prev_time);
  prev_time = now_time;  
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

//  scale.power_up();
//  scale.power_down();             // put the ADC in sleep mode

//  Serial.print("read: \t\t");
//  Serial.println(scale.read()); // print a raw reading from the ADC
//
//  Serial.print("read average: \t\t");
//  Serial.println(scale.read_average(20)); // print the average of 20 readings from the ADC
//
//  Serial.print("get value: \t\t");
//  Serial.println(scale.get_value(5)); // print the average of 5 readings from the ADC minus the tare weight, set with tare()
//
//  Serial.print("get units: \t\t");
//  Serial.println(scale.get_units(5), 1); // print the average of 5 readings from the ADC minus tare weight, divided by the SCALE parameter set with set_scale
//
//  Serial.println("Readings:");
 
