/*---------------------------------------------------------------------------
 * Copyright (c) 2020-2024 Arm Limited (or its affiliates).
 * All rights reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Licensed under the Apache License, Version 2.0 (the License); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an AS IS BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 *      Name:    Hello.c
 *      Purpose: Hello World based on RTX
 *
 *---------------------------------------------------------------------------*/

#include "main.h"
#include <stdio.h>
#include "cmsis_os2.h"                  // ::CMSIS:RTOS2


/*---------------------------------------------------------------------------
 * Application main thread
 *---------------------------------------------------------------------------*/

static int count = 0;

static void app_main_thread (void *argument) {
  (void)argument;

  while (1)  {
    printf ("Hello World %d\r\n", count);
    if (count >= 100) printf ("\x04");  // EOT (0x04) stops simulation
    count++;
    osDelay (100);
  }
}

/*---------------------------------------------------------------------------
 * Application initialization
 *---------------------------------------------------------------------------*/
int app_main (void) {
  osKernelInitialize();                 // Initialize CMSIS-RTOS2
  osThreadNew(app_main_thread, NULL, NULL);
  osKernelStart();                      // Start thread execution
  return 0;
}
