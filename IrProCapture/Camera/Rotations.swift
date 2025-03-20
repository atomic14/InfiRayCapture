//
//  Rotations.swift
//  IrProCapture
//
//  Created by Chris Greening on 18/3/25.
//
import AppKit

/// A structure representing an image orientation option with transformation capabilities.
///
/// OrientationOption provides:
/// - Named orientation presets (e.g., "Up", "Left mirrored")
/// - Dimension translation for rotated orientations
/// - Support for comparison and hashing in collections
struct OrientationOption: Hashable, Equatable {
    /// The display name of the orientation
    let name: String
    /// The Core Graphics orientation value
    let orientation: CGImagePropertyOrientation
    
    /// Translates dimensions based on the orientation.
    ///
    /// This method handles dimension swapping for rotated orientations:
    /// - For vertical orientations (up/down), dimensions remain unchanged
    /// - For horizontal orientations (left/right), dimensions are swapped
    ///
    /// - Parameters:
    ///   - x: The original width
    ///   - y: The original height
    /// - Returns: A tuple of (width, height) adjusted for the orientation
    func translateX(_ x: CGFloat, y: CGFloat) -> (CGFloat, CGFloat) {
        switch orientation {
        case .up, .down, .upMirrored, .downMirrored:
            return (x, y)
        case .left, .right, .leftMirrored, .rightMirrored:
            return (y, x)
        }
    }
}

/// The collection of available image orientation options.
///
/// This array provides all possible combinations of:
/// - Standard orientations (up, down, left, right)
/// - Mirrored variants of each orientation
let orientationOptions: [OrientationOption] = [
    OrientationOption(name: "Up", orientation: .up),
    OrientationOption(name: "Up mirrored", orientation: .upMirrored),
    OrientationOption(name: "Down", orientation: .down),
    OrientationOption(name: "Down mirrored", orientation: .downMirrored),
    OrientationOption(name: "Left", orientation: .left),
    OrientationOption(name: "Left mirrored", orientation: .leftMirrored),
    OrientationOption(name: "Right", orientation: .right),
    OrientationOption(name: "Right mirrored", orientation: .rightMirrored)
]
