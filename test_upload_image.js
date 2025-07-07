const fs = require('fs');
const path = require('path');
const axios = require('axios');
const FormData = require('form-data');

const uploadImage = async (filePath) => {
  const form = new FormData();
  form.append('attachment', fs.createReadStream(filePath));

  try {
    const response = await axios.post('http://localhost:3000/upload-image', form, {
      headers: {
        ...form.getHeaders(),
        'Authorization': 'Bearer YOUR_AUTH_TOKEN', // Replace with a valid token if needed
      },
    });
    console.log('Upload successful:', response.data);
  } catch (error) {
    console.error('Upload failed:', error.response ? error.response.data : error.message);
  }
};

// Replace with the path to a sample image file
const sampleImagePath = path.join(__dirname, 'path_to_your_sample_image.jpg');
uploadImage(sampleImagePath);
