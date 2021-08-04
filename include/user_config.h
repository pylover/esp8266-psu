#ifndef USER_CONFIG_H
#define USER_CONFIG_H

#define USE_OPTIMIZE_PRINTF

#define __name__ "esp8266-psu"
#define __version__ "0.1.0"

#define PARAMS_DEFAULT_ZONE "dev"
#define PARAMS_DEFAULT_NAME __name__

// Available IO     IO  INIT
#define GPIO0        0  //    (LED, FLASH, FOTABTN)
#define GPIO1        1  //    (UART TX)
#define GPIO2        2  //    ()
#define GPIO3        3  //    (Relay, UART RX)


// LED
#define LED_MUX                PERIPHS_IO_MUX_GPIO0_U     
#define LED_NUM                GPIO0
#define LED_FUNC            FUNC_GPIO0

// POWERRELAY
#define POWERRELAY_MUX                PERIPHS_IO_MUX_U0RXD_U    
#define POWERRELAY_NUM                GPIO3
#define POWERRELAY_FUNC                FUNC_GPIO3

#endif

