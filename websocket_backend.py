from flask import Flask
from flask_socketio import SocketIO, emit
import base64
import cv2
import numpy as np
from ultralytics import YOLO
import traceback

app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins="*", async_mode="eventlet", max_http_buffer_size=100000000)
model = YOLO(r"C:\Users\lenovo\Programming\CNIC_Detection\runs\best.pt")  # Adjust path to your model

def decode_base64_image(base64_data):
    img_bytes = base64.b64decode(base64_data)
    nparr = np.frombuffer(img_bytes, np.uint8)
    return cv2.imdecode(nparr, cv2.IMREAD_COLOR)

@socketio.on('connect')
def on_connect():
    print("✅ Client connected")

@socketio.on('disconnect')
def on_disconnect(data):
    print("❌ Client disconnected")
    
@socketio.on_error_default
def default_error_handler(e):
    print(f"🔥 An error occurred: {e}")
    traceback.print_exc()

@socketio.on('frame')
def handle_frame(data):
    try:
        image_b64 = data.get('image')
        if not image_b64:
            raise ValueError("No image data received")

        frame = decode_base64_image(image_b64)
        if frame is None:
            raise ValueError("Failed to decode image")

        results = model.predict(source=frame, save=False)
        boxes = results[0].boxes

        bbox_list = []
        if boxes is not None and len(boxes) > 0:
            for box in boxes:
                coords = box.xyxy[0].cpu().numpy().astype(int).tolist()
                conf = float(box.conf[0])
                cls_id = int(box.cls[0])
                class_name = model.names[cls_id]

                # Draw bounding box and label on the image
                x1, y1, x2, y2 = coords
                label = f"{class_name} {conf:.2f}"
                cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
                cv2.putText(frame, label, (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX,
                            0.5, (0, 255, 0), 2)

                bbox_list.append({
                    "class": class_name,
                    "confidence": conf,
                    "bbox": coords
                })

            # Save the image with bounding boxes
            cv2.imwrite("yolo_output.jpg", frame)

        emit('bboxes', {'boxes': bbox_list})
    except Exception as e:
        print("❌ Exception:", str(e))
        traceback.print_exc()
        emit('error', {'message': str(e)})

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=5001)
