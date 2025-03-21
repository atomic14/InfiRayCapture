import Foundation

/// Scale factor for thermal image display.
/// This value determines how much the raw thermal image is enlarged for viewing.
let SCALE: Float = 4.0

/// Width of the scaled thermal image in pixels.
/// Calculated as the raw sensor width (256) multiplied by the scale factor.
let WIDTH: Float = 256.0 * SCALE

/// Height of the scaled thermal image in pixels.
/// Calculated as the raw sensor height (192) multiplied by the scale factor.
let HEIGHT: Float = 192.0 * SCALE
