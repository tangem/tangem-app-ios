//
//  TlvReader.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

struct TlvReader {
    func read(_ data: Data) -> [Tlv]? {
        let dataStream = InputStream(data: data)
        dataStream.open()
        
        var tags = [Tlv]()
        while dataStream.hasBytesAvailable {
            guard let tagCode = readTagCode(dataStream),
                let dataLength = readTagLength(dataStream),
                let data = readTagData(dataStream, count: dataLength) else {
                    return nil
            }
                        
            let tlvItem = Tlv(tagRaw: tagCode, value: data)
            tags.append(tlvItem)
        }
        
        dataStream.close()
        return tags
    }
    
    private func readTagCode(_ dataStream: InputStream) -> Byte? {
        guard let tagBytes = dataStream.readByte() else {
            print("Failed to read tag code")
            return nil
        }
        
        return tagBytes
    }
    
    private func readTagLength(_ dataStream: InputStream) -> Int? {
        guard let shortLengthBytes = dataStream.readByte() else {
            print("Failed to read tag lenght")
            return nil
        }
        
        if (shortLengthBytes == 0xFF) {
            guard let longLengthBytes = dataStream.readBytes(count: 2) else {
                print("Failed to read tag long lenght")
                return nil
            }
            
            return Int(lengthValue: longLengthBytes)
        } else {
            return Int(lengthValue: Data([shortLengthBytes]))
        }
    }
    
    private func readTagData(_ dataStream: InputStream, count: Int) -> Data? {
        guard count > 0 else {
            return Data()
        }
        
        guard let dataBytes = dataStream.readBytes(count: count) else {
            print("Failed to read tag data")
            return nil
        }
        
        return dataBytes
    }
}
