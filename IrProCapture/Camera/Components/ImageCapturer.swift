//
//  ImageCapturer.swift
//  IrProCapture
//
//  Created by Chris Greening on 17/3/25.
//

import Foundation
import CoreGraphics
import CoreImage
import ImageIO
import UniformTypeIdentifiers

/// A class responsible for saving thermal images to disk.
///
/// The `ImageCapturer` class handles the process of saving thermal images to disk
/// as PNG files, separating this concern from the main Camera class.
class ImageCapturer {
    
    /// The CoreImage context used for image processing
    private let ciContext = CIContext()
    
    /// Saves the provided image to disk as a PNG file.
    /// 
    /// - Parameters:
    ///   - image: The CGImage to save
    ///   - outputURL: The URL where the image should be saved
    /// - Returns: A boolean indicating whether the save operation was successful
    func saveImage(image: CGImage, outputURL: URL) -> Bool {
        // If the file already exists we need to delete it
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }
        
        // Create an image destination for PNG format
        guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            print("Failed to create image destination")
            return false
        }
        
        // Add the CGImage to the destination
        CGImageDestinationAddImage(destination, image, nil)
        
        // Finalize the image writing
        if CGImageDestinationFinalize(destination) {
            print("Image saved successfully!")
            return true
        } else {
            print("Failed to save image")
            return false
        }
    }
} 