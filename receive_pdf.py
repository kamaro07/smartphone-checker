import os
from flask import Flask, request, jsonify
from werkzeug.utils import secure_filename

app = Flask(__name__)
UPLOAD_FOLDER = 'PDFs'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({'error': 'No file part in the request'}), 400
    
    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400
        
    if file:
        filename = secure_filename(file.filename)
        file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(file_path)
        print(f"File saved successfully to: {file_path}")
        return jsonify({'message': 'File uploaded successfully', 'path': file_path}), 200

if __name__ == '__main__':
    print(f"Starting server to receive PDFs... Saving to {os.path.abspath(UPLOAD_FOLDER)}")
    print("Listening on http://0.0.0.0:8000")
    app.run(host='0.0.0.0', port=8000)
