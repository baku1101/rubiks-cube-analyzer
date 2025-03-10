# Rubik's Cube Analyzer

## Overview
The Rubik's Cube Analyzer is a multi-platform application designed to connect to the GAN12 UI Maglev Rubik's Cube for solving analysis. The application aims to provide users with tools to analyze their cube-solving techniques and improve their skills.

## Features
- **Bluetooth Connectivity**: Connect to the GAN12 UI Maglev Rubik's Cube via Bluetooth for real-time data exchange.
- **Cube State Representation**: Visualize the current state of the Rubik's Cube.
- **Move History**: Track and display the history of moves made during solving.
- **Analysis Tools**: Analyze cube moves and solutions to enhance solving strategies.
- **Cross-Platform Support**: Initially developed for Windows, with plans to expand to Android and iOS.

## Project Structure
```
rubiks-cube-analyzer
├── lib
│   ├── main.dart
│   ├── app.dart
│   ├── models
│   │   ├── cube_state.dart
│   │   ├── move.dart
│   │   └── solve_analysis.dart
│   ├── services
│   │   ├── bluetooth_service.dart
│   │   ├── cube_connection_service.dart
│   │   └── analytics_service.dart
│   ├── screens
│   │   ├── home_screen.dart
│   │   ├── connection_screen.dart
│   │   ├── analysis_screen.dart
│   │   └── settings_screen.dart
│   ├── utils
│   │   └── cube_algorithms.dart
│   └── widgets
│       ├── cube_visualization.dart
│       └── move_history.dart
├── android
│   ├── app
│   └── build.gradle
├── ios
│   └── Runner
├── windows
│   └── runner
├── test
│   └── unit_tests.dart
├── pubspec.yaml
└── README.md
```

## Getting Started
1. **Clone the Repository**: 
   ```
   git clone <repository-url>
   cd rubiks-cube-analyzer
   ```

2. **Install Dependencies**: 
   ```
   flutter pub get
   ```

3. **Run the Application**: 
   - For Windows:
     ```
     flutter run -d windows
     ```
   - For Android:
     ```
     flutter run -d android
     ```
   - For iOS:
     ```
     flutter run -d ios
     ```

## Future Development
- Expand the application to support Android and iOS platforms.
- Enhance the analysis tools with more advanced algorithms.
- Improve the user interface for better user experience.

## Contributing
Contributions are welcome! Please submit a pull request or open an issue for any suggestions or improvements.

## License
This project is licensed under the MIT License - see the LICENSE file for details.