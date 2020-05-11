const {DEPLOY_ENV} = process.env
const express = require('express');
const app = express();

const PORT = 8081;

app.get('/', (req, res) => {
    res.send(`DEPLOY_ENV: ${DEPLOY_ENV}\nHello World!`);
});

app.get('/status', (req, res) => {
    res.send();
});

app.listen(PORT, () => {
    console.log(`[APP] Listening on: 0.0.0.0:${PORT}`);
});
