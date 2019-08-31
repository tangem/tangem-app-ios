//
//  TLVReader.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

struct TLVReader {
    
    private let dataStream: InputStream
    
    init(_ bytes: [UInt8]) {
        dataStream = InputStream(data: Data(bytes: bytes))
    }
    
    func read() -> [CardTag:CardTLV] {
        dataStream.open()
        guard dataStream.hasBytesAvailable else {
            return [:]
        }
        
        var tags = [CardTag:CardTLV]()
        while dataStream.hasBytesAvailable {
            
            if let tagCode = readTagCode(dataStream),
                let dataLength = readTagLength(dataStream) {
                let data = readTagData(dataStream, count: dataLength)
                let tlvItem = CardTLV(tagCode, value: data)
                tags[tagCode] = tlvItem
            }
            
        }
        
        dataStream.close()
        return tags
    }
    
    private func readTagCode(_ dataStream: InputStream) -> CardTag? {
        guard let tagBytes = dataStream.readBytes(1)?.first else {
            return nil
        }
        
        let tagCode = CardTag(rawValue: tagBytes) ?? CardTag.unknown
        
        if tagCode == .unknown {
            let hex = tagBytes.toAsciiHex()
            print("Unknown tag: \(hex)")
        }
        
        return tagCode
    }
    
    private func readTagLength(_ dataStream: InputStream) -> Int? {
        let lengthBytes: [UInt8]? = {
            guard let shortLengthBytes = dataStream.readBytes(1)?.first else {
                return nil
            }
            
            if (shortLengthBytes == 0xFF) {
                guard let longLengthBytes = dataStream.readBytes(2) else {
                    return nil
                }
                return longLengthBytes
                
            } else {
                return [shortLengthBytes]
            }
        }()
        
        let length = Int(from: lengthBytes)
        return length
    }
    
    private func readTagData(_ dataStream: InputStream, count: Int) -> [UInt8]? {
        guard let dataBytes = dataStream.readBytes(count) else {
            return nil
        }
        return dataBytes
    }
}
