*** Settings ***
Suite Setup                   Setup
Suite Teardown                Teardown
Test Setup                    Reset Emulation
Test Teardown                 Test Teardown
Library                       String
Resource                      ${RENODEKEYWORDS}

*** Variables ***
${UART}                       sysbus.usart1

*** Test Cases ***
Should Start ThreadX demo
    [Documentation]           Runs ThreadX demo app on STM32F7 platform.
    [Tags]                    azure-rtos  threadx

    Execute Command           set bin @${CURDIR}/stm32f746_threadx_demo.elf
    Execute Command           include @scripts/single-node/stm32f746_azure_rtos.resc

    Execute Command           showAnalyzer ${UART}
    Create Terminal Tester    ${UART}

    Start Emulation

    Wait For Line On Uart     **** ThreadX Win32 Demonstration **** (c) 1996-2020 Microsoft Corporation

Should Check ThreadX timer accuracy
    [Documentation]           Runs ThreadX demo app on STM32F7 platform and checks that timer ticks accurately
    [Tags]                    azure-rtos  threadx  timers
    Set Test Variable         ${SLEEP_TIME}                 100
    Set Test Variable         ${SLEEP_TOLERANCE}            .1
    Set Test Variable         ${REPEATS}                    20

    Execute Command           set bin @${CURDIR}/stm32f746_threadx_demo.elf
    Execute Command           include @scripts/single-node/stm32f746_azure_rtos.resc

    Execute Command           showAnalyzer ${UART}
    Create Terminal Tester    ${UART}

    Start Emulation

    ${l}=               Create List
    ${MIN_SLEEP_TIME}=  Evaluate  ${SLEEP_TIME} - ${SLEEP_TOLERANCE}
    ${MAX_SLEEP_TIME}=  Evaluate  ${SLEEP_TIME} + ${SLEEP_TOLERANCE}

    :FOR  ${i}  IN RANGE  0  ${REPEATS}
    \     ${r}        Wait For Line On Uart     thread 0 events sent    treatAsRegex=true
    \                 Append To List            ${l}  ${r.timestamp}

    :FOR  ${i}  IN RANGE  1  ${REPEATS}
    \     ${i1}=  Get From List   ${l}                       ${i - 1}
    \     ${i2}=  Get From List   ${l}                       ${i}
    \     ${d}=   Evaluate        ${i2} - ${i1}
    \             Should Be True  ${d} >= ${MIN_SLEEP_TIME}      Too short sleep detected between entries ${i} and ${i + 1}: expected ${SLEEP_TIME}, got ${d}
    \             Should Be True  ${d} <= ${MAX_SLEEP_TIME}      Too long sleep detected between entires ${i} and ${i + 1}: expected ${SLEEP_TIME}, got ${d}

    