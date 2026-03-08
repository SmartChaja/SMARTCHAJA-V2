/**
 * appRedirect.js
 *
 * Firebase Cloud Function: appRedirect
 *
 * Detects the user's device (Android / iOS) from the User-Agent header
 * and redirects to the appropriate app store.
 * All extra query parameters (e.g. sn, device_id) are preserved and
 * forwarded so the hardware team's links remain intact.
 *
 * Endpoint: GET https://chaja-kiganjani.web.app/app
 * Examples:
 *   /app                          → plain redirect
 *   /app?sn=ABC123                → redirect + sn preserved in log
 *   /app?sn=ABC123&device_id=456  → redirect + both params preserved
 */

const {onRequest} = require("firebase-functions/v2/https");
const {logger} = require("firebase-functions");

// ─── Store URLs ──────────────────────────────────────────────────────────────
const ANDROID_PACKAGE = "com.tjrsmartchaja.smartchaja";
const PLAY_STORE_URL =
  `https://play.google.com/store/apps/details?id=${ANDROID_PACKAGE}`;

const APP_STORE_ID = "6756839159";
const APP_STORE_URL =
  `https://apps.apple.com/app/id${APP_STORE_ID}`;

// Fallback – shown to desktop browsers or unknown devices
const FALLBACK_URL = "https://chaja-kiganjani.web.app/";
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Detects device type from the User-Agent string.
 * @param {string} ua - User-Agent header value
 * @return {'android'|'ios'|'unknown'}
 */
function detectDevice(ua = "") {
  const lower = ua.toLowerCase();
  if (/android/.test(lower)) return "android";
  if (/iphone|ipad|ipod/.test(lower)) return "ios";
  return "unknown";
}

exports.appRedirect = onRequest(
    {region: "us-central1", cors: true},
    (req, res) => {
      const ua = req.headers["user-agent"] || "";
      const device = detectDevice(ua);

      // Log extra hardware params for traceability (never block the redirect)
      const {sn, device_id: deviceId, ...rest} = req.query;
      if (sn || deviceId) {
        logger.info("App download request", {
          device,
          sn: sn || null,
          device_id: deviceId || null,
          extra: Object.keys(rest),
        });
      }

      let destination;
      if (device === "android") {
        destination = PLAY_STORE_URL;
      } else if (device === "ios") {
        destination = APP_STORE_URL;
      } else {
        destination = FALLBACK_URL;
      }

      res.redirect(302, destination);
    },
);
