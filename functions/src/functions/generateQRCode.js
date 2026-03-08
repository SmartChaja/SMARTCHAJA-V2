/**
 * generateQRCode.js
 *
 * Firebase Cloud Function: generateQRCode
 *
 * Returns a PNG QR code image that encodes the universal app-redirect link.
 * The hardware team can call this endpoint to generate a fresh QR code at
 * any time without touching the codebase.
 *
 * Endpoint: GET https://chaja-kiganjani.web.app/qr
 *
 * Optional query params:
 *   size  – pixel size of the QR code image (default: 300)
 *
 * Examples:
 *   /qr            → 300×300 QR code
 *   /qr?size=500   → 500×500 QR code
 */

const {onRequest} = require("firebase-functions/v2/https");
const {logger} = require("firebase-functions");
const QRCode = require("qrcode");

// The universal link that gets encoded into the QR code.
// Hardware team should print QR codes pointing to this base URL.
// They may append parameters if needed:  BASE_URL?sn={SN}&device_id={DEVICE_ID}
const BASE_URL = "https://chaja-kiganjani.web.app/app";

exports.generateQRCode = onRequest(
    {region: "us-central1", cors: true},
    async (req, res) => {
      try {
        // Optional: allow a custom suffix / extra params to be baked in
        const suffix = req.query.params ? `?${req.query.params}` : "";
        const url = `${BASE_URL}${suffix}`;

        // Size (px) – clamp between 100 and 1000 to avoid abuse
        const rawSize = parseInt(req.query.size, 10);
        const size = Math.min(Math.max(isNaN(rawSize) ? 300 : rawSize, 100), 1000);

        logger.info("Generating QR code", {url, size});

        // Generate QR code as a PNG Buffer
        const pngBuffer = await QRCode.toBuffer(url, {
          type: "png",
          width: size,
          margin: 2,
          color: {
            dark: "#1A1A2E", // dark navy – matches app brand
            light: "#FFFFFF",
          },
          errorCorrectionLevel: "H", // High – survives printing/damage
        });

        res.set("Content-Type", "image/png");
        res.set("Cache-Control", "public, max-age=86400"); // cache 24 h
        res.status(200).send(pngBuffer);
      } catch (err) {
        logger.error("QR code generation failed", err);
        res.status(500).json({error: "Failed to generate QR code"});
      }
    },
);
