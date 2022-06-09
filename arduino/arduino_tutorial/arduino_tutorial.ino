#include <Arduino.h>

#define TIMERFREQUENCY 4

static bool state = true;

// GLOBAL VARIABLES
// const in pins[3] = {5,6,2};
// const int pwm_channel = 9;
// const int max_val = 255;

// BASIC COMMANDS
// digitalWrite(pin, HIGH/LOW);
// digitalRead(pin);
// analogWrite(pin, 0-255);
// analogRead(pin);
// delay(ms);

// ADVANCED COMMANDS
// Serial.begin(9600);
// Serial.println(TCCR1B, BIN);
// millis(); // count time since start of arduino
// attachInterrupt(0, function, CHANGE);
// PORTB = B00111111; // register manipulation

// TIMERS Paramters table
// TC0, 0, TC0_IRQn  =>  TC0_Handler()
// TC0, 1, TC1_IRQn  =>  TC1_Handler()
// TC0, 2, TC2_IRQn  =>  TC2_Handler()
// TC1, 0, TC3_IRQn  =>  TC3_Handler()
// TC1, 1, TC4_IRQn  =>  TC4_Handler()
// TC1, 2, TC5_IRQn  =>  TC5_Handler()
// TC2, 0, TC6_IRQn  =>  TC6_Handler()
// TC2, 1, TC7_IRQn  =>  TC7_Handler()
// TC2, 2, TC8_IRQn  =>  TC8_Handler()

void TC3_Handler(void) {

  if (state == true) {
    digitalWrite(LED_BUILTIN, HIGH); 
    state = false;
  } else {
    digitalWrite(LED_BUILTIN, LOW);
    state = true;
  }
}

void startTimer(Tc *tc, uint32_t channel, IRQn_Type irq, uint32_t frequency) {
  pmc_set_writeprotect(false);
  pmc_enable_periph_clk((uint32_t)irq);
  TC_Configure(tc, channel, TC_CMR_WAVE | TC_CMR_WAVSEL_UP_RC |TC_CMR_TCCLKS_TIMER_CLOCK4);
  uint32_t rc = VARIANT_MCK/128/frequency;
  TC_SetRA(tc, channel, rc/2); //50% high, 50% low
  TC_SetRC(tc, channel, rc);
  tc->TC_CHANNEL[channel].TC_IER=TC_IER_CPCS;
  tc->TC_CHANNEL[channel].TC_IDR=~TC_IER_CPCS;
  NVIC_ClearPendingIRQ(irq);
  NVIC_EnableIRQ(irq);
  TC_Start(tc, channel);
}


void setup() {
  // pinpout setup
  pinMode(LED_BUILTIN, OUTPUT);

  // timer setup  
  startTimer(TC1, 0, TC3_IRQn, TIMERFREQUENCY);

  // serial com init
  Serial.begin(57600);
  Serial.setTimeout(2);
  Serial.println("Initialisation");
 
}

void loop() {
  // write
  Serial.println("loop");

  delay(100);
}
