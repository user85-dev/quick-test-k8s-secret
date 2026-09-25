const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({ secret_msg: process.env.secret_msg || null, api_key: process.env.api_key || null });
});

app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
