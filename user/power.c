#include "user_config.h"
#include "power.h"


void power_init() {
    PIN_FUNC_SELECT(POWERRELAY_MUX, POWERRELAY_FUNC);
    PIN_PULLUP_EN(POWERRELAY_MUX);
    GPIO_OUTPUT_SET(GPIO_ID_PIN(POWERRELAY_NUM), 1);
}
