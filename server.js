// server.js
import express from 'express'
import path from 'path'
const app = express()
const PORT = process.env.PORT || 8000

const publicDir = path.join(process.cwd(), 'public')
app.use((req, res, next) => {
  // Allow cross-origin (optional; useful عند استدعاء من domain آخر)
  res.setHeader('Access-Control-Allow-Origin', '*')
  next()
})
app.use(express.static(publicDir, { extensions: ['html'] }))

// Ensure USDZ content-type
app.get('/*.usdz', (req, res) => {
  const filePath = path.join(publicDir, req.path)
  res.setHeader('Content-Type', 'model/vnd.usdz+zip')
  res.sendFile(filePath, err => {
    if (err) res.status(404).send('Not found')
  })
})

app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`)
})
app.use(express.static('folder / public')); 