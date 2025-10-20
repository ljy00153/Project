# Copilot Instructions for This Codebase

## Overview
This project models and analyzes the Eyeriss hardware accelerator for deep learning, focusing on mapping, memory usage, and performance evaluation for linear layers. The codebase is organized into a few core C++ files, each responsible for a major aspect of the simulation and analysis pipeline.

## Key Components
- `main.cpp`: Entry point. Sets up a linear layer configuration and invokes the mapping and analysis pipeline.
- `mapper.cpp`: Defines `EyerissMapper`, which generates hardware mappings, evaluates them, and selects the top configurations based on a custom score (energy, latency, etc.).
- `eyeriss.cpp`: Implements `EyerissAnalyzer`, which models hardware behavior, memory usage, energy, and performance metrics for a given mapping.
- `data_type.h`: Contains all struct definitions for layer shapes, hardware parameters, mapping parameters, and analysis results.

## Data Flow
1. `main.cpp` creates a `LinearShapeParam` and passes it to `EyerissMapper::run()`.
2. `EyerissMapper` generates possible mappings, evaluates each using `EyerissAnalyzer`, and prints the top-k configurations.
3. `EyerissAnalyzer` computes memory usage, energy, latency, and other metrics for each mapping.

## Build & Run
- No build scripts are present; compile manually:
  ```sh
  g++ main.cpp -o main.exe
  ./main.exe
  ```
  (On Windows, use `main.exe` to run.)
- All logic is header-only or included via `#include "*.cpp"` for simplicity.

## Project-Specific Patterns
- **All major classes are defined in `.cpp` files and included directly.** This is non-standard but intentional for this small simulation.
- **No external dependencies** beyond the C++ standard library.
- **Hardware and mapping parameters are hardcoded** for the Eyeriss architecture.
- **Evaluation metrics** (energy, latency, etc.) are custom and domain-specific.

## Extending or Modifying
- To add new hardware models, extend `EyerissHardwareParam` and update `EyerissAnalyzer`.
- To change mapping search, modify `EyerissMapper::generate_mappings()`.
- For new analysis metrics, update `AnalysisResult` and `EyerissAnalyzer::summary()`.

## Example: Adding a New Metric
- Add a field to `AnalysisResult` in `data_type.h`.
- Compute the value in `EyerissAnalyzer::summary()`.
- Print or use the value in `EyerissMapper::run()`.

## Conventions
- Use `using namespace std;` throughout.
- All code is in the global namespace.
- Comments and variable names may mix English and Chinese.

---
For questions about hardware modeling or mapping logic, see `mapper.cpp` and `eyeriss.cpp` for the main algorithms and scoring logic.
