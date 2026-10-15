// Draws the JSON written by dump.luau into PNGs, using three.js in a headless browser.
//   node tools/preview/render.cjs <dump folder> <png folder> [model ...]
// With no models, every JSON file in the dump folder is drawn.
const http = require("http")
const fs = require("fs")
const path = require("path")

const playwright = require(process.env.PLAYWRIGHT_PATH || "playwright")
const [dumpDir, pngDir, ...only] = process.argv.slice(2)
const root = __dirname

const types = { ".html": "text/html", ".js": "text/javascript", ".mjs": "text/javascript", ".json": "application/json" }
const server = http.createServer((req, res) => {
  const url = decodeURIComponent(req.url.split("?")[0])
  const file = url.startsWith("/out/") ? path.join(dumpDir, url.slice(5)) : path.join(root, url)
  if (!fs.existsSync(file) || fs.statSync(file).isDirectory()) { res.writeHead(404); return res.end() }
  res.writeHead(200, { "content-type": types[path.extname(file)] || "application/octet-stream" })
  fs.createReadStream(file).pipe(res)
})

;(async () => {
  await new Promise((r) => server.listen(0, r))
  const port = server.address().port
  fs.mkdirSync(pngDir, { recursive: true })
  const browser = await playwright.chromium.launch({
    executablePath: process.env.CHROME_PATH || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome",
    args: ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist", "--no-sandbox"],
  })
  const names = (only.length ? only : fs.readdirSync(dumpDir).map((f) => f.replace(/\.json$/, ""))).filter((n) => n !== "lighting")
  for (const name of names) {
    const beach = name === "beach"
    const views = beach ? ["street", "high", "shop", "huts", "umbrellas"] : ["iso", "side"]
    for (const view of views) {
      const page = await browser.newPage({ viewport: beach ? { width: 960, height: 540 } : { width: 480, height: 400 } })
      page.on("pageerror", (e) => console.error(name, e.message))
      const w = beach ? 960 : 480, h = beach ? 540 : 400
      await page.goto(`http://localhost:${port}/scene.html?model=${name}&view=${view}&w=${w}&h=${h}`)
      await page.waitForFunction("window.__ready === true", null, { timeout: 60000 })
      await page.screenshot({ path: path.join(pngDir, `${name}${beach || view !== "iso" ? "-" + view : ""}.png`) })
      await page.close()
    }
  }
  await browser.close()
  server.close()
})()
