//
//  ImageCache.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import UIKit.UIImage
import Combine
import var CommonCrypto.CC_MD5_DIGEST_LENGTH
import func CommonCrypto.CC_MD5
import typealias CommonCrypto.CC_LONG

//[REDACTED_TODO_COMMENT]

// Declares in-memory image cache
public protocol ImageCacheType: AnyObject {
    // Returns the image associated with a given url
    func image(for url: URL) -> UIImage?
    // Inserts the image of the specified url in the cache
    func insertImage(_ image: UIImage?, for url: URL)
    // Removes the image of the specified url in the cache
    func removeImage(for url: URL)
    // Removes all images from the cache
    func removeAllImages()
    // Accesses the value associated with the given key for reading and writing
    subscript(_ url: URL) -> UIImage? { get set }
}

public final class ImageCache: ImageCacheType {

    public struct Config {
        public let countLimit: Int
        public let memoryLimit: Int

        public static let defaultConfig = Config(countLimit: 100, memoryLimit: 1024 * 1024 * 70) // 100 MB
    }

    private lazy var imageCache: NSCache<AnyObject, AnyObject> = {
        let cache = NSCache<AnyObject, AnyObject>()
        cache.countLimit = config.countLimit
        return cache
    }()
    private lazy var decodedImageCache: NSCache<AnyObject, AnyObject> = {
        let cache = NSCache<AnyObject, AnyObject>()
        cache.totalCostLimit = config.memoryLimit
        return cache
    }()
    private let fileManager: FileManager = .default

    private var cacheFolderUrl: URL {
        let url = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("ImageCache")
        if !fileManager.fileExists(atPath: url.path){
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
        return url
    }

    private let config: Config

    public init(config: Config = Config.defaultConfig) {
        self.config = config
    }

    public func image(for url: URL) -> UIImage? {
        if let decodedImage = decodedImageCache.object(forKey: url as AnyObject) as? UIImage {
            return decodedImage
        }

        func saveToDecodedCache(image: UIImage) {
            decodedImageCache.setObject(image as AnyObject, forKey: url as AnyObject, cost: image.diskSize)
        }

        if let image = imageCache.object(forKey: url as AnyObject) as? UIImage {
            let decodedImage = image.decodedImage()
            saveToDecodedCache(image: decodedImage)
            return decodedImage
        }

        if let data = try? Data(contentsOf: localFileUrl(for: url)),
           let image = UIImage(data: data) {
            saveToDecodedCache(image: image)
            return image
        }
        return nil
    }

    public func insertImage(_ image: UIImage?, for url: URL) {
        guard let image = image else { return removeImage(for: url) }
        let decompressedImage = image.decodedImage()

        imageCache.setObject(decompressedImage, forKey: url as AnyObject, cost: 1)
        decodedImageCache.setObject(image as AnyObject, forKey: url as AnyObject, cost: decompressedImage.diskSize)
        if let data = image.pngData() {
            do {
                try data.write(to: localFileUrl(for: url))
            } catch {
                print("Failed to write to file. Reason: \(error)")
            }
        }
    }

    public func removeImage(for url: URL) {
        imageCache.removeObject(forKey: url as AnyObject)
        decodedImageCache.removeObject(forKey: url as AnyObject)
        try? fileManager.removeItem(at: url)
    }

    public func removeAllImages() {
        imageCache.removeAllObjects()
        decodedImageCache.removeAllObjects()
        try? fileManager.removeItem(at: cacheFolderUrl)
    }

    public subscript(_ key: URL) -> UIImage? {
        get { image(for: key) }
        set { insertImage(newValue, for: key) }
    }

    private func localFileUrl(for remoteUrl: URL) -> URL {
        let fileName = remoteUrl.absoluteString.md5String
        return cacheFolderUrl.appendingPathComponent(fileName)
    }
}

fileprivate extension String {
    var md5String: String {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        let messageData = data(using:.utf8)!
        var digestData = Data(count: length)

        _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
            messageData.withUnsafeBytes { messageBytes -> UInt8 in
                if let messageBytesBaseAddress = messageBytes.baseAddress, let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                    let messageLength = CC_LONG(messageData.count)
                    CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
                }
                return 0
            }
        }
        return digestData.map { String(format: "%02hhx", $0) }.joined()
    }
}

fileprivate extension UIImage {

    func decodedImage() -> UIImage {
        guard let cgImage = cgImage else { return self }
        let size = CGSize(width: cgImage.width, height: cgImage.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: cgImage.bytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        context?.draw(cgImage, in: CGRect(origin: .zero, size: size))
        guard let decodedImage = context?.makeImage() else { return self }
        return UIImage(cgImage: decodedImage)
    }

    // Rough estimation of how much memory image uses in bytes
    var diskSize: Int {
        guard let cgImage = cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
    }
}
