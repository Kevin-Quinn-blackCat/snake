# FPGA-based VGA Snake Game with Infrared Control

This project presents a classic Snake game implemented entirely in pure Verilog HDL on an Altera (Intel) FPGA. Developed as a personal learning endeavor for FPGA design, it showcases fundamental digital logic design principles and hardware-software co-design.

## Key Features

*   **Game Logic:** Implements the classic Snake game mechanics.
*   **Display Output:** Utilizes a VGA interface with an RGB565 weighted resistor protocol for video signal transmission.
*   **Control Input:** Employs an infrared (IR) signal sensor (HS0038B) compatible with the NEC protocol for game control.
*   **Hardware Platform:** Targets an Intel Cyclone IV series FPGA.
*   **Auxiliary Displays:** Includes a 6-digit 8-segment display driven by an HC595 shift register, and general-purpose LEDs for status indication.
*   **Implementation Language:** Pure Verilog HDL.

## Hardware Components

*   **Core FPGA Device:** Intel Cyclone IV series, specifically `EP4CE10F17C8`.
*   **Infrared Sensor:** `HS0038B` (NEC protocol compatible).
*   **Numeric Display Driver:** `HC595` shift register for a 6-digit 8-segment display.
*   **Visual Indicators:** Standard LEDs.
*   **Video Output:** VGA port utilizing an RGB565 weighted resistor DAC.

## Project Structure

The project is organized into the following directories:

*   `doc/`: Contains documentation, including compilation instructions and design sketches.
*   `rtl/`: Houses all Verilog source code files (`.v`).
    *   `game_ctrl/`: This subdirectory contains the core game control logic.
        *   `snake.v`: Serves as the top-level design file for the entire project.
    *   Other files within `rtl/`: Implement signal reception, transmission, and processing for various peripheral hardware components.
*   `quartus_prj/`: Contains the Quartus II 13.0 project files.
    *   `ip_core/`: Stores all intellectual property (IP) core files used in the design.
*   `sim/`: Holds simulation files and the corresponding ModelSim project files for verification.
