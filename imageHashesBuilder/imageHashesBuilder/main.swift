//
//  main.swift
//  imageHashesBuilder
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CommonCrypto

func hex(data: Data) -> String {
    var string = ""

    data.enumerateBytes { pointer, index, _ in
        for i in index..<pointer.count {
            string += String(format: "%02X", pointer[i])
        }
    }

    return string
}

func sha256(_ data: Data) -> Data? {
    guard let res = NSMutableData(length: Int(CC_SHA256_DIGEST_LENGTH)) else {
        return nil
    }

    CC_SHA256((data as NSData).bytes, CC_LONG(data.count), res.mutableBytes.assumingMemoryBound(to: UInt8.self))
    return res as Data
}


print("Calculate hashes")
let fileManager = FileManager.default
let enumerator = fileManager.enumerator(atPath: CommandLine.arguments[1])

var dictionary = [String: String]()
while let element = enumerator?.nextObject() as? String {
    print(element)
    if element.hasSuffix(".png") {
        let split = element.split(separator: "/")
        guard split.count > 1 else { continue }
        
        let name = String(split[1].replacingOccurrences(of: ".imageset", with: ""))
        let url = URL(fileURLWithPath: CommandLine.arguments[1] + element)
        let data = try! Data(contentsOf: url)
        let hexValue = hex(data: data).data(using: String.Encoding.utf8)!
        let hash = sha256(hexValue)!
        dictionary[name] = hex(data:hash)
    }
}

 (dictionary as NSDictionary).write(toFile: CommandLine.arguments[2], atomically: true)


