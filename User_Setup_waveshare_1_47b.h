// Waveshare ESP32-S3-LCD-1.47B - 172x320 ST7789
// Pins from https://www.waveshare.com/wiki/ESP32-S3-LCD-1.47B
// Based on User_Setup_cyd_2usb.h

#define ST7789_DRIVER
#define TFT_RGB_ORDER TFT_BGR

#define TFT_WIDTH  172
#define TFT_HEIGHT 320

#define TFT_INVERSION_OFF

// Waveshare 1.47B LCD pins (from wiki)
#define TFT_MOSI 45
#define TFT_SCLK 40
#define TFT_CS   42
#define TFT_DC   41
#define TFT_RST  39
#define TFT_BL   46

#define TOUCH_CS  -1  // No touch on 1.47B

#define LOAD_GLCD
#define LOAD_FONT2
#define LOAD_FONT4
#define LOAD_FONT6
#define LOAD_FONT7
#define LOAD_FONT8
#define LOAD_GFXFF
#define SMOOTH_FONT

#define SPI_FREQUENCY       80000000
#define SPI_READ_FREQUENCY  40000000
#define SPI_TOUCH_FREQUENCY 2500000

#define USE_HSPI_PORT
