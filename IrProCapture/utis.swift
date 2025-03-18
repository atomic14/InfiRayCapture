//
//  utis.swift
//  IrProCapture
//
//  Created by Chris Greening on 17/3/25.
//
import CoreGraphics
import CoreImage
import Foundation


func convertUInt8ArrayToCIImage(pixelData: [UInt8], width: Int, height: Int) -> CIImage? {
    // Create a bitmap context with the correct dimensions
    let bytesPerRow = width * 4
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let data = Data(bytes: pixelData, count: pixelData.count)
    return CIImage(bitmapData: data, bytesPerRow: bytesPerRow, size: CGSize(width: width, height: height), format: .RGBA8, colorSpace: colorSpace)
}
