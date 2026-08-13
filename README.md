# AR-MR Liquid (local test)

Quick start (local test with GLB preview and USDZ Quick Look via ngrok):

1. Prepare files
   - Create folder `ar-mr-site`
   - Inside it create `public/` and place:
     - `ar-mr-liquid.html` (the viewer) inside `public/`
     - any test models (e.g. `model.usdz`, `model.glb`) into `public/`
   - Put `server.js`, `package.json`, `.gitignore`, `README.md` at repo root.

2. Install & run server
   - Node >= 16 recommended
   - In terminal:
     npm install
     npm start
   - Server runs on http://localhost:8000 and serves files from `public/`.

3. Test on desktop (GLB)
   - Open: http://localhost:8000/ar-mr-liquid.html
   - Click "Open" → choose GLB or use the input
   - Toggle MR (split) to show side-by-side

4. Test USDZ Quick Look on iPhone (requires HTTPS)
   - Install ngrok (https://ngrok.com) and run:
     ngrok http 8000
   - Use the generated https URL (e.g. https://abcd1234.ngrok.io)
   - Put model.usdz in public/ and open https://abcd1234.ngrok.io/model.usdz in Safari (or open the page and use "Open in AR").

5. Notes & troubleshooting
   - If USDZ doesn't open: make sure HTTPS and Content-Type header (server.js sets it).
   - For large files use S3 or Git LFS; do not commit >100MB to git without LFS.