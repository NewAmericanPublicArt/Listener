#include "LPD8806.h"
#include "SPI.h"

// Example to control LPD8806-based RGB LED Modules in a strip
//todo:
//smooth blinking
//final one 4 strands 10 meters each, 4 ft apart, 320 lights on each strand
// 320px by 4 px.
/*****************************************************************************/

#define NORMAL 1
#define INVERSE 0

// Choose which 2 pins you will use for output.
// Can be any valid output pins.
int dataPin = 2;
int clockPin = 3;
int sensor = 0;
int sensorPin= A0;
int meterVal = 0;
int color = 0;
int maxVal = 30;
// colors : 16000=bright red, 1=darkblue,
int primary = 16000;
int complement = 1000;
int background = 1;
int mode = INVERSE;
int flag = false;
int mic_high = 1000; // increase this number to decrease mic sensitivity
int mic_low = 300;
int first_led = 0;
int total_leds = 160;

// Set the first variable to the NUMBER of pixels. 32 = 32 pixels in a row
// The LED strips are 32 LEDs per meter but you can extend/cut the strip
LPD8806 strip = LPD8806(total_leds, dataPin, clockPin);

// you can also use hardware SPI, for ultra fast writes by leaving out the
// data and clock pin arguments. This will 'fix' the pins to the following:
// on Arduino 168/328 thats data = 11, and clock = pin 13
// on Megas thats data = 51, and clock = 52
//LPD8806 strip = LPD8806(32);

void setup() {
  // Start up the LED strip
  Serial.begin(9600);
  strip.begin();
}


void loop() {

  int filtered;
  int decayed;
  int numPixels;

  int i;
  sensor = analogRead(sensorPin); //this will be between 0 and 1023
  filtered = filter(sensor);
  decayed = decay(filtered);
  meterVal = map(decayed, mic_low, mic_high, first_led, total_leds);
  numPixels = strip.numPixels();

  for (i=0; i <= numPixels; i++) {
    //if (mode == NORMAL) {
        //if(i < meterVal) {
        if((i > (numPixels/2) - meterVal)&&(i<(numPixels/2)+meterVal)){
            strip.setPixelColor(i, primary);
        } else if((i==(numPixels/2) - meterVal)||(i==(numPixels/2)+meterVal)) {
           strip.setPixelColor(i, (complement -= 1));
        } else {
            strip.setPixelColor(i, background);
        }
   /* } else {
       if(i < meterVal) {
            strip.setPixelColor(numPixels - i, primary);
        } else if(i == meterVal) {
            strip.setPixelColor(numPixels - i, (complement -= 1));
        } else {
            strip.setPixelColor(numPixels - i, 0);
        }
    }*/
  }
  // this changes the color if the noise is loud
  if(meterVal > 30) {
       primary += 2000;
       complement += 2000;
  }

  /*
  // this flips everything around //
  if (mode == NORMAL){
    if (meterVal > 60){
      flag = true;
    }
    if (flag == true && meterVal < 60) {
      flag = false;
      mode = INVERSE;
    }
  } else if( mode == INVERSE) {
    if (meterVal > 60) {
      flag = true;
    }
    if (flag == true && meterVal < 60) {
      flag = false;
      mode = NORMAL;
    }
  }
  */

// delay(10);
  strip.show();
}


// -- the decay function --
// smaller cycle % # makes decay faster
int decay(int sensor)
{
  static float peak = 0;
  static float divisor = 1;
  static int cycle = 0;
  float current = 0;

  cycle++;

  current = peak/divisor;

  if ((float)sensor > current) {
    divisor = 1;
    peak = (float)sensor;
    current = peak;
  } else if ((divisor < 1000) && !(cycle % 5)) {
    divisor = divisor * 1.04;
  }

  return current;

}

// -- filter out the flicker --

int filter(int sensor)
{
  static float last = 0;
  float diff;

  diff = sensor - last;
  if ((diff > 25.0) || (diff < -5.0)) {
    last = sensor;
    return (int)sensor;
  } else {
    return (int)last;
  }
}
