//
//  Rotations.swift
//  IrProCapture
//
//  Created by Chris Greening on 18/3/25.
//
import AppKit

struct RotationOption: Hashable, Equatable {
    let name: String
    let rotation: CGImagePropertyOrientation
    
    func translateX(_ x: CGFloat, y: CGFloat) -> (CGFloat, CGFloat) {
        switch rotation {
        case .up, .down, .upMirrored, .downMirrored:
            return (x, y)
        case .left, .right, .leftMirrored, .rightMirrored:
            return (y, x)
        }
    }
}

let rotationOptions: [RotationOption] = [
    RotationOption(name: "Up", rotation: .up),
    RotationOption(name: "Up mirrored", rotation: .upMirrored),
    RotationOption(name: "Down", rotation: .down),
    RotationOption(name: "Down mirrored", rotation: .downMirrored),
    RotationOption(name: "Left", rotation: .left),
    RotationOption(name: "Left mirrored", rotation: .leftMirrored),
    RotationOption(name: "Right", rotation: .right),
    RotationOption(name: "Right mirrored", rotation: .rightMirrored)
]
