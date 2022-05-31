// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ################ INCLUDE #################
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#define TE 100           // sampling time in ms

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ########### DECLARE VARIABLES ############
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

HX711 scale1;
HX711 scale2;
HX711 scale3;

String input_sequence = "";

bool flag_verbose = true;

float reading1 = 0;
float reading2 = 0;
float reading3 = 0;

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
  init_loadcells();

  Serial.flush();
  Serial.println("Ready !");
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

void loop() {

  // LOAD CELL
  read_loadcells();

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
  }

  // COMMUNICATION
  if (flag_verbose) {
    Serial.print("HX711 TRUST: ");
    Serial.println(-reading1);
    Serial.print("HX711 TORQUE: ");
    Serial.println(reading2 - reading3 - (reading2+reading3)/2);
    Serial.println();
  } else {
    Serial.print(millis());
    Serial.print(",");
    Serial.print(reading1);
    Serial.print(",");
    Serial.print(reading2);
    Serial.print(",");
    Serial.print(reading3);
    Serial.println(";");
  }
  
  delay(TE);
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ############### FUNCTIONS ################
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
 
