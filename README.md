# CNIC Real-Time Detection System

A real-time Pakistani CNIC (Computerized National Identity Card) detection system utilizing WebSocket communication between a Flask-SocketIO backend and Flutter mobile application for live object detection and bounding box visualization.

**Note**: This project is a fork of [ZemCS/CNIC_Detection](https://github.com/ZemCS/CNIC_Detection). The required YOLO model file (`best.pt`) can be obtained from the original repository.

## Overview

This system implements real-time CNIC detection capabilities through a WebSocket-based architecture. The solution streams camera frames from a Flutter mobile application to a Python backend server, which performs YOLO-based object detection and returns bounding box coordinates for live visualization on the mobile interface.

## System Architecture

The system consists of two primary components:
- **Backend Server**: Flask-SocketIO server with YOLO model integration
- **Mobile Application**: Flutter camera interface with real-time WebSocket communication

## Features

- Real-time video stream processing with WebSocket communication
- YOLO-based CNIC detection with live bounding box overlay
- Automatic coordinate transformation for accurate visualization
- Bi-directional communication with error handling
- Live confidence score display
- Frame rate optimization with configurable streaming intervals

## System Requirements

### Backend Requirements
- Python 3.7 or higher
- Flask framework
- Flask-SocketIO for WebSocket support
- OpenCV (cv2) for image processing
- Ultralytics YOLO
- NumPy for numerical operations
- Eventlet for asynchronous processing

### Mobile Application Requirements
- Flutter SDK 3.0 or higher
- Dart 3.0 or higher
- Socket.IO client library
- Camera package for Flutter
- Network connectivity for WebSocket communication

## Installation

### Backend Configuration

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/cnic-realtime-detection.git
   cd cnic-realtime-detection
   ```

2. Install required Python dependencies:
   ```bash
   pip install flask flask-socketio opencv-python ultralytics numpy eventlet
   ```

3. Configure the YOLO model path in `websocket_backend.py`:
   ```python
   model = YOLO(r"path/to/your/best.pt")
   ```

4. Ensure the YOLO model file is accessible at the specified path.

### Mobile Application Configuration

1. Navigate to the Flutter application directory:
   ```bash
   cd flutter_app
   ```

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Add required dependencies to `pubspec.yaml`:
   ```yaml
   dependencies:
     camera: ^0.10.5
     socket_io_client: ^2.0.3
   ```

4. Configure the WebSocket server address in `main.dart`:
   ```dart
   socket = IO.io(
     'http://SERVER_IP_ADDRESS:5001',
     // ... configuration options
   );
   ```

5. Add camera permissions as specified in the primary system documentation.

## Usage

### Server Deployment

Execute the following command to start the WebSocket server:
```bash
python websocket_backend.py
```

The server will be accessible at `http://0.0.0.0:5001` with WebSocket support enabled.

### Mobile Application Execution

Launch the Flutter application:
```bash
flutter run
```

The application will automatically attempt to connect to the configured WebSocket server upon startup.

## WebSocket Communication Protocol

### Client to Server Events

#### `frame` Event
- **Purpose**: Transmit camera frame data for processing
- **Payload Structure**:
  ```json
  {
    "image": "base64_encoded_image_data"
  }
  ```

### Server to Client Events

#### `bboxes` Event
- **Purpose**: Return detection results with bounding box coordinates
- **Payload Structure**:
  ```json
  {
    "boxes": [
      {
        "class": "cnic_front",
        "confidence": 0.85,
        "bbox": [x1, y1, x2, y2]
      }
    ]
  }
  ```

#### `error` Event
- **Purpose**: Communicate processing errors to client
- **Payload Structure**:
  ```json
  {
    "message": "error_description"
  }
  ```

## Technical Implementation

### Backend Processing Pipeline

1. **WebSocket Connection Management**: Handles client connections and disconnections
2. **Base64 Image Decoding**: Converts transmitted image data to OpenCV format
3. **YOLO Model Inference**: Processes frames for CNIC detection
4. **Bounding Box Extraction**: Extracts coordinates, confidence scores, and class labels
5. **Result Transmission**: Sends detection results via WebSocket emission
6. **Error Handling**: Manages exceptions and communicates errors to clients

### Mobile Application Features

1. **Camera Initialization**: Configures camera controller with medium resolution preset
2. **WebSocket Connection**: Establishes and manages real-time communication
3. **Frame Streaming**: Captures and transmits images at configurable intervals
4. **Coordinate Transformation**: Converts YOLO coordinates to screen coordinates
5. **Bounding Box Rendering**: Draws detection results with custom painter
6. **Stream Control**: Provides start/stop functionality for streaming

### Coordinate Transformation Algorithm

The system implements precise coordinate transformation to map YOLO detection coordinates to screen display coordinates:

```dart
// Aspect ratio calculations
final previewAspectRatio = previewSize.width / previewSize.height;
final screenAspectRatio = screenSize.width / screenSize.height;

// Scale factors for coordinate mapping
final scaleX = displayWidth / yoloWidth;
final scaleY = displayHeight / yoloHeight;
```

## Configuration Parameters

### Streaming Configuration
- **Frame Transmission Interval**: 1000 milliseconds (configurable)
- **Camera Resolution**: Medium preset for optimal performance
- **WebSocket Transport**: WebSocket protocol with automatic connection
- **Buffer Size**: 100MB maximum HTTP buffer size

### Detection Parameters
- **YOLO Input Dimensions**: 640x448 pixels (primary), 480x720 pixels (alternative)
- **Bounding Box Styling**: 2.0px stroke width, red color scheme
- **Confidence Display**: Two decimal precision
- **Label Background**: Semi-transparent overlay (0.7 opacity)

## Performance Optimization

### Backend Optimizations
- **Asynchronous Processing**: Eventlet-based asynchronous event handling
- **Memory Management**: Efficient NumPy array operations
- **Error Recovery**: Comprehensive exception handling with traceback logging
- **CORS Configuration**: Wildcard origin support for development flexibility

### Mobile Application Optimizations
- **Frame Rate Control**: Configurable streaming intervals to prevent server overload
- **Memory Efficiency**: Proper disposal of camera controller and socket connections
- **UI Responsiveness**: Non-blocking UI updates during streaming operations
- **Connection Management**: Automatic reconnection capabilities

## Error Handling

The system implements comprehensive error handling mechanisms:

### Backend Error Management
- **Image Decoding Failures**: Validation of base64 data integrity
- **YOLO Model Errors**: Exception handling for inference failures  
- **WebSocket Communication**: Connection state monitoring and error emission
- **Resource Management**: Proper cleanup of processing resources

### Mobile Application Error Management
- **WebSocket Disconnections**: Automatic reconnection attempts
- **Camera Access Issues**: Permission validation and error reporting
- **Network Connectivity**: Connection state monitoring and user feedback
- **Rendering Errors**: Safe coordinate transformation with boundary clamping

## Project Structure

```
realtime-identity-card-annotation/
├── websocket_backend.py     # Flask-SocketIO server implementation
├── yolo_output.jpg         # Processed frame output (generated)
├── realtime_cnic_detection/
│   ├── lib/
│   │   └── main.dart       # Complete Flutter application
│   └── pubspec.yaml        # Flutter dependencies
└── README.md              # Documentation
```

## Development Considerations

### Security Considerations
- **Network Security**: Implement proper authentication for production deployment
- **Data Validation**: Validate all incoming WebSocket data
- **Resource Limits**: Configure appropriate buffer sizes and connection limits
- **CORS Policy**: Restrict origins in production environments

### Scalability Considerations
- **Connection Management**: Implement connection pooling for multiple clients
- **Model Optimization**: Consider model quantization for improved inference speed
- **Load Balancing**: Distribute processing load across multiple server instances
- **Caching Strategies**: Implement frame caching to reduce redundant processing

## Contributing

Contributions are welcome through the standard GitHub workflow. Please ensure all changes maintain compatibility with the WebSocket communication protocol and adhere to the established coding standards.

## License

This project is distributed under the MIT License. See the LICENSE file for complete terms and conditions.

## Support

For technical support and issue reporting, please utilize the GitHub issue tracking system. Include relevant server logs and client-side error messages when submitting support requests.
