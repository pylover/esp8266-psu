#ifndef _POWER_H_
#define _POWER_H_

#include <osapi.h>
#include <gpio.h>


#define HTTPSTATUS_POWERON  "700 On"
#define HTTPSTATUS_POWEROFF "701 Off"
#define POWERON() GPIO_OUTPUT_SET(GPIO_ID_PIN(POWERRELAY_NUM), 0)
#define POWEROFF() GPIO_OUTPUT_SET(GPIO_ID_PIN(POWERRELAY_NUM), 1)
#define POWERSTATUS() (GPIO_INPUT_GET(GPIO_ID_PIN(POWERRELAY_NUM))? \
    HTTPSTATUS_POWEROFF: HTTPSTATUS_POWERON)

void power_init();

#endif
