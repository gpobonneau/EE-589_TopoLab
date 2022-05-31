// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ################ INCLUDE #################
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#include <Servo.h>

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ############ HARDWARE SETUP ##############
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#define ESC_CTRL_PIN    10
#define RPM_SENSOR_PIN  9

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#define MIN_DUTY  1000   // min pulse length in um
#define MAX_DUTY  2000   // max pulse length in um
#define SLOWRATE  15     // command signal slowed @X times compared to acquisition rate
#define TE        10           // sampling time in ms
#define NB_POLES  17     // nb of electrical poles of motor

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ########### DECLARE VARIABLES ############
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Servo esc;

String input_sequence = "";
int i = 0;

volatile float raw_rpm_value = 0;
volatile float motor_speed = 100;
volatile float duty_cycle = 2000;

bool flag_verbose = false;
bool flag_auto = false;
bool flag_ramp = false;
bool flag_prbs = false;

bool reset_flag_auto = true;
bool reset_flag_ramp = true;

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
        break;
      case 'r' :
        flag_ramp = true;
        flag_auto = false;
        flag_prbs = false;
        input_sequence.remove(0,1);
        auto_motor_speed_target = input_sequence.toInt();
        break;
//      case 'a' :
//        motor_speed = 0;
//        flag_auto = true;
//        flag_ramp = false;
//        flag_prbs = false;
//        input_sequence.remove(0,1);
//        auto_motor_speed_target = input_sequence.toInt();
//        break;
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

float set_motor_speed(float speed_percentage) { // sets motor speed
  
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

void auto_ramp(float target) { //  /!\ FUNCTION NEEDS DEBBUGING

  static int k = 10;
  static int l = 15;
  
  if (reset_flag_auto) {
    k = 10;
    l = 15;
    reset_flag_auto = false;
    reset_flag_ramp = true;
  }

  if (l>=15) {
    ramp(k);
  }

  if (reset_flag_ramp) {
    ramp(k);
    k += 5;
    l = 0;
  }

  l=+1;

  if (k > target) {
    reset_flag_auto = true;
    flag_auto = false;
  } 

}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

void ramp(float target) { // produces a ramp up to given motor speed
  
  static int i = 4;
  static int j = 0;
  static bool flag_stop = false; // set to true to set motor speed to 0 after 5s
  
  if (reset_flag_ramp) {
    i = 4;
    j = 0;
    reset_flag_ramp = false;
  }
  
  motor_speed = motor_speed+2.5; // 2.5% points increments

  if (flag_stop) {
    if (motor_speed == target) {
      if (j < 25) { // hold target speed for 5 seconds
        i -= 1;
        j += 1;
      }
    }
  }
  
  if (motor_speed >= target) {
    flag_ramp = false;
    reset_flag_ramp = true;
    if (flag_stop) {
      motor_speed = 0;
    }
  }
  
  motor_speed = set_motor_speed(motor_speed);
  i += 1;
  
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

void prbs_signal() { // generates prbs signal

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

void ext_rising() { // external interupt function to measure RPM signal frequency
  
  static long int prev_time = 0;
  static long int now_time = 0;

  now_time = micros();
  raw_rpm_value = 1000000.f/(now_time - prev_time);
  prev_time = now_time;  
}
 
