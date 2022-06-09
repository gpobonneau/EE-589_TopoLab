// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ################ INCLUDE #################
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ############ HARDWARE SETUP ##############
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#define PIN_RPM_OUT   A0
#define PIN_RPM_IN    8
#define PIN_VGND      7

#define MAX_RPM         1750    // true rpm given by MAX_RPM*NB_POLES/2
#define MAX_DAC         1023    // 2^10 - 1

#define DELAY           10      // loop time delay in ms

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ########### DECLARE VARIABLES ############
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

volatile unsigned int rpm_analog = 0;
volatile float rpm_raw = 0;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ################## MAIN ##################
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

void setup() {
  // INITIALISATION
  Serial.begin(9600);
  Serial.setTimeout(3);
  delay(DELAY);
  Serial.println("Booting...");
  pinMode(LED_BUILTIN, OUTPUT);

  // Set additionnal ground
  pinMode(PIN_VGND, OUTPUT);
  digitalWrite(PIN_VGND, LOW);
  
  // TRUE DAC CONFIGUATION
  pinMode(PIN_RPM_OUT, OUTPUT);
  analogWriteResolution(10); // Set analog out resolution to max, 10-bits
  analogReadResolution(12); // Set analog input resolution to max, 12-bits

  // SETUP INTERRUPTS
  Serial.println("Enabling interrupts");
  attachInterrupt(PIN_RPM_IN, int0_rpm_in, RISING);
  
  Serial.flush();
  Serial.println("Ready !");
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

void loop() {

  // compute value to send to analog pin
  rpm_analog = (unsigned int) round(rpm_raw*MAX_DAC/MAX_RPM);

  // Write rpm value to pin
  analogWrite(PIN_RPM_OUT, rpm_analog);

  delay(DELAY);
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ############### FUNCTIONS ################
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

void int0_rpm_in() { // external interrupt function to measure RPM signal frequencyitp
  
  static long int time_prev = 0; // previous interrupt time
  static long int time_curr = 0; // current time
  static int i = 0;

  time_curr = micros();
  
  rpm_raw = 1000000.f/(time_curr - time_prev);
  time_prev = time_curr;  

  // safety bounds
  if (rpm_raw > MAX_RPM) {
    rpm_raw = MAX_RPM;
  } else if (rpm_raw < 0) {
    rpm_raw = 0;
  }

  // blink led at interrupt freq
  if (i<10) {
    digitalWrite(LED_BUILTIN, HIGH);
    i++;
  } else if (i<19) {
    digitalWrite(LED_BUILTIN, LOW);
    i++;
  } else {
    i=0;
  }

}

 
