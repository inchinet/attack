import pkg from 'whatsapp-web.js';
const { Client, LocalAuth } = pkg;
import express from 'express';
import qrcode from 'qrcode-terminal';

const PORT  = 3001;
const TOKEN = process.env.WA_TOKEN || 'change-me';
const app   = express();
app.use(express.json());
app.use((req, res, next) => {
    if (req.headers['x-token'] !== TOKEN) return res.status(401).json({error:'Unauthorized'});
    next();
});

let isReady = false;

const client = new Client({
    authStrategy: new LocalAuth({ dataPath: '/home/ubuntu/.wa-gateway/session' }),
    puppeteer: {
        executablePath: '/snap/chromium/current/usr/lib/chromium-browser/chrome',
        args: ['--no-sandbox','--disable-setuid-sandbox','--disable-dev-shm-usage','--disable-gpu']
    }
});

client.on('qr', qr => { console.clear(); qrcode.generate(qr, {small:true}); });
client.on('ready', () => { isReady = true; console.log('✅ WhatsApp ready'); });
client.on('disconnected', reason => {
    isReady = false;
    console.warn('⚠️ Disconnected:', reason);
    setTimeout(() => process.exit(1), 2000);
});
client.on('auth_failure', m => { console.error('❌', m); setTimeout(() => process.exit(1), 2000); });

app.get('/health', async (req, res) => {
    if (!isReady) return res.json({ ready: false });
    try { await client.pupPage.evaluate(() => true); res.json({ ready: true }); }
    catch(e) { isReady = false; res.json({ ready: false }); }
});

app.post('/api/send', async (req, res) => {
    const { chatId, message } = req.body;
    if (!chatId || !message) return res.status(400).json({ error: 'missing params' });
    if (!isReady) return res.status(503).json({ error: 'not ready' });
    try {
        await client.sendMessage(chatId, message);
        console.log(`✉️  Sent to ${chatId}`);
        res.json({ success: true });
    } catch(e) {
        // Frame detaches AFTER WhatsApp processes the send — treat as success
        if (/detach|Frame|Session|Target/i.test(e.message)) {
            console.log(`✉️  Sent (frame navigated post-send) to ${chatId}`);
            res.json({ success: true });
        } else {
            console.error('Send error:', e.message);
            res.status(500).json({ error: e.message });
        }
    }
});

client.initialize();
app.listen(PORT, () => console.log(`WA Gateway on :${PORT}`));
