//
//  Rotations.swift
//  IrProCapture
//
//  Created by Chris Greening on 18/3/25.
//
import AppKit

struct OrientationOption: Hashable, Equatable {
    let name: String
    let orientation: CGImagePropertyOrientation
    
    func translateX(_ x: CGFloat, y: CGFloat) -> (CGFloat, CGFloat) {
        switch orientation {
        case .up, .down, .upMirrored, .downMirrored:
            return (x, y)
        case .left, .right, .leftMirrored, .rightMirrored:
            return (y, x)
        }
    }
}

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
