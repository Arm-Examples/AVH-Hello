[![License](https://img.shields.io/github/license/Arm-Examples/AVH-Hello?label)](https://github.com/Arm-Examples/AVH-Hello/blob/main/LICENSE)
[![Build and Execution Test](https://img.shields.io/github/actions/workflow/status/Arm-Examples/AVH-Hello/hello-ci.yml?logo=arm&logoColor=0091bd&label=Build%20and%20Execution%20Test)](https://github.com/Arm-Examples/AVH-Hello/tree/main/.github/workflows/hello-ci.yml)

# AVH-Hello

This repository contains a CI project with a [test matrix](https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs) that uses [GitHub Actions](https://github.com/features/actions) on a [GitHub-hosted runner](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners/about-github-hosted-runners) with an Ubuntu Linux system.


## Quick Start

1. Install [Keil Studio for VS Code](https://marketplace.visualstudio.com/items?itemName=Arm.keil-studio-pack) from the VS Code marketplace.
2. Clone this repository (for example using [Git in VS Code](https://code.visualstudio.com/docs/sourcecontrol/intro-to-git)) or download the ZIP file. Then open the base folder in VS Code.
3. Open the [CMSIS View](https://mdk-packs.github.io/vscode-cmsis-solution-docs/userinterface.html#2-main-area-of-the-cmsis-view) in VS Code and use the ... menu to choose an example via *Select Active Solution from workspace*.
4. The related tools and software packs are downloaded and installed. Review progress with *View - Output - CMSIS Solution*.
5. In the CMSIS view, use the [Action buttons](https://github.com/ARM-software/vscode-cmsis-csolution?tab=readme-ov-file#action-buttons) to build, load and debug the example on the hardware.


## Examples Description
| Example name                              | Description   |
|---                                        |---            |
| [Hello](Hello.csolution.yml)              | The application module [`hello.c`](.\hello.c) prints "Hello World" with count value to the UART output. It is configured for [Arm Virtual Hardware - Fixed Virtual Platforms](https://arm-software.github.io/AVH/main/simulation/html/index.html) (AVH FVP), but it is easy to re-target it to hardware that provides a [CMSIS Driver:USART] (https://arm-software.github.io/CMSIS_6/latest/Driver/group__usart__interface__gr.html). |



## Project Structure

The project is defined as [`CMSIS Solution Project`](https://github.com/Open-CMSIS-Pack/cmsis-toolbox/blob/main/docs/YML-Input-Format.md) that describes the build process for the [CMSIS-Toolbox](https://github.com/Open-CMSIS-Pack/cmsis-toolbox/blob/main/README.md).

Files and directories                          | Content
:----------------------------------------------|:----------
[`.github/workflows/`](./.github/workflows)    | GitHub Action file [`hello-ci.yml`](./.github/workflows/hello-ci.yml) defines a test matrix (with compiler, target, build types) that is iterated to build and run different variants of the application.
[`Board_IO/`](./Board_IO)                      | I/O re-targeting to a CMSIS-Driver UART interface.
[`FVP/`](./FVP)                                | Configuration files for the [AVH FVP](https://arm-software.github.io/AVH/main/simulation/html/index.html) simulation models.
[`RTE/Device/`](./RTE/Device/)                 | Includes for each device (target-type) the `RTE_Device.h` file with CMSIS-Driver configuration.
[`RTE/CMSIS/`](./RTE/CMSIS)                    | RTOS configuration file `RTX_Config.h` used for all devices (targets).
[`Hello.csolution.yml`](./Hello.csolution.yml) | Lists the required packs and defines the hardware target and build-types.
[`Hello.cproject.yml`](./Hello.cproject.yml)   | Defines the source files and the software components.
[`cdefault.yml`](./cdefault.yml)               | Contains the setup for different compilers (AC6, GCC, IAR, and CLANG).
[`vcpkg-configuration.json`](./vcpkg-configuration.json) | Specifies the required tools for [vcpkg](https://learn.arm.com/learning-paths/microcontrollers/vcpkg-tool-installation/installation/); it is configured to install the latest tool versions.
[`main.c`](./main.c) / [`main.h`](./main.h)    | Application startup with CMSIS-RTOS
[`hello.c`](./hello.c)                         | Test application that prints "Hello World \<count\>".

> **Note:**
>
> The privileged mode in `RTX_Config.h` is enabled, to allow the **USART** initialization.

The workflow allows to build and test the application on different host systems, for example local development computers that are Windows based and CI systems that run Linux.


## Prerequisites for commandline build and execution

- The required tools are installed from [ARM Tools Artifactory](https://www.keil.arm.com/artifacts/) using [vcpkg](https://learn.arm.com/learning-paths/microcontrollers/vcpkg-tool-installation/installation/).
- The required Software Packs are installed using the [CMSIS-Toolbox](https://github.com/Open-CMSIS-Pack/cmsis-toolbox/blob/main/README.md) `cbuild` utility with the option `--packs`.


## Build on Local Development Computer

To generate the application for a specific target-type, build-type, and compiler execute the following command line:

```txt
> cbuild Hello.csolution.yml --packs --context Hello.Debug+CS300 --toolchain AC6 --rebuild
```

Parameters\Flags              | Description
:-----------------------------|:----------
**`--toolchain`**             | Specifies which compiler (GCC or AC6) is used to build the executable.
**`--rebuild`**               | Forces a clean rebuild.
**`--packs`**                 | Forces the download of required packs.
**`--update-rte`**            | Updates the Run-Time Environment (RTE directory).
**`Debug`**                   | Selects build-type (Debug or Release).
**`CS300`**                   | Selects target-type (CM0 is Cortex-M0, CS300 is Corstone-300).


## Execute on Local Development Computer

To execute the application on an [AVH FVP simulation model](https://arm-software.github.io/AVH/main/simulation/html/index.html) use the following command line:

```txt
> FVP_Corstone_SSE-300 -a ./out/Hello/CS300/Debug/AC6/Hello.axf -f ./FVP/FVP_Corstone_SSE-300/fvp_config.txt --simlimit 60
```

Parameters\Flags              | Description
:-----------------------------|----------
**`-a`**                      |  Defines the path to the generated executable.
**`-f`**                      | Specifies the configuration file needed for the [Arm Virtual Hardware](https://arm-software.github.io/AVH/main/overview/html/index.html) model.
**`--simlimit`**              | Set the maximum time in seconds for the simulation.

> **Notes:**
>
> - When using an FVP model for the first time you may need to configure firewalls for the Terminal output.
> - Depending on the local development computers, the `--simlimit 60` exceeds to execute the full test run. If this is the case increase the value, i.e. to `--simlimit 200`.
> - Some FVP models simulate very fast and may not synchronize with the Terminal program. In this case use `--quantum 100` to slow down to view the Terminal output.


## Continuous Integration (CI)

The underlying build system of [Keil Studio](https://www.keil.arm.com/) uses the [CMSIS-Toolbox](https://open-cmsis-pack.github.io/cmsis-toolbox/) and CMake. [CI](https://en.wikipedia.org/wiki/Continuous_integration) is effectively supported with:

- Tool installation based on a single [`vcpkg-configuration.json`](./vcpkg-configuration.json) file for desktop and CI environments.
- CMSIS solution files (`*.csolution.yml`) that enable seamless builds in CI, for example using GitHub actions.

| <div style="width:150px"> CI Workflow </div>    | Description |
|---                                              |--- |
| [hello-ci.yml](/.github/workflows/hello-ci.yml) | It uses the same commands for build and execute, except that the tools use parameters from the [test matrix](https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs). The test matrix validates the application with GCC and Arm Compiler using a `Debug` and `Release` build. It builds and runs the application across the different [Arm Cortex-M processors](https://www.arm.com/products/silicon-ip-cpu?families=cortex-m) and various [Arm Corstone sub-systems](https://www.arm.com/products/silicon-ip-subsystems). It total it validates that 56 different variants execute correct on AVH FVP simulation models that represent a typical implementation of an Arm processor. For the execution on the AVH FVP models, the UART ouput is redirected to a log file using the parameter **`-C`**. This output is checked for correctness. |


## More CI Examples

Arm is using CI validation tests for many projects. The list below are only a few examples that may be used to derive own CI test projects.

Resource           | Description
:------------------|:------------------
[AVH_CI_Template](https://github.com/Arm-Examples/AVH_CI_Template)     | CI Template for unit test automation that uses GitHub Actions.
[CMSIS Version 6](https://github.com/ARM-software/CMSIS_6/actions)     | Runs a CMSIS-Core validation test across the supported processors using multiple compilers.
[RTOS2 Validation](https://github.com/ARM-software/CMSIS-RTX/actions)  | Runs the CMSIS-RTOS2 validation across Keil RTX using source and library variants.
[STM32H743I-EVAL_BSP](https://github.com/Open-CMSIS-Pack/STM32H743I-EVAL_BSP) | Build test of a Board Support Pack (BSP) with MDK-Middleware [Reference Applications](https://github.com/Open-CMSIS-Pack/cmsis-toolbox/blob/main/docs/ReferenceApplications.md) using Arm Compiler or GCC. The artifacts store the various example projects for testing on the hardware board.
[MDK Middleware](https://github.com/ARM-software/MDK-Middleware)       | Build test of MDK-Middleware library and device agonistic [Reference Applications](https://github.com/Open-CMSIS-Pack/cmsis-toolbox/blob/main/docs/ReferenceApplications.md) using Arm Compiler or GCC.
[TFL Micro Speech](https://github.com/arm-software/AVH-TFLmicrospeech) | This example project shows the Virtual Streaming Interface with Audio input and uses [software layers](https://github.com/Open-CMSIS-Pack/cmsis-toolbox/blob/main/docs/build-overview.md#software-layers) for retargeting.


## Other Developer Resources

Resource           | Description
:------------------|:------------------
[AVH FVP Documentation](https://arm-software.github.io/AVH/main/overview/html/index.html) | Is a comprehensive documentation about Arm Virtual Hardware.
[AVH FVP Support Forum](https://community.arm.com/support-forums/f/arm-virtual-hardware-targets-forum) | Arm Virtual Hardware is supported via a forum. Your feedback will influence future roadmap.
[AVH-MLOps](https://github.com/ARM-software/AVH-MLOps) | Shows the setup of a Docker container with foundation tools for CI and MLOps systems.

## Related Webinar Recordings

- [MDK v6 Technical Deep Dive](https://on-demand.arm.com/flow/arm/devhub/sessionCatalog/page/pubSessCatalog/session/1713958336497001CQIR)
- [CLI builds using CMSIS-Toolbox](https://on-demand.arm.com/flow/arm/devhub/sessionCatalog/page/pubSessCatalog/session/1708432622207001feYV)
- [Using CMSIS-Toolbox and Keil MDK v6 in CI/CD Workflows](https://on-demand.arm.com/flow/arm/devhub/sessionCatalog/page/pubSessCatalog/session/1718006126984001DUAn)
- [Using CMSIS-View and CMSIS-Compiler](https://on-demand.arm.com/flow/arm/devhub/sessionCatalog/page/pubSessCatalog/session/1706872120089001ictY)
- [Data streaming with CMSIS-Stream and SDS](https://on-demand.arm.com/flow/arm/devhub/sessionCatalog/page/pubSessCatalog/session/1709221848113001nOU5)
