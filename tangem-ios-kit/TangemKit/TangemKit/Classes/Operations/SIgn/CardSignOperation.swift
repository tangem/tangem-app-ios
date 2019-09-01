//
//  CardSignOperation.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import CryptoSwift

class CardSignOperation: Operation {
    override func main() {
        
    }
    
    func sign(hashes: [[UInt8]], pin2: String = "000") throws {
        guard hashes.count <= 10 else {
            throw TangemException.tooMuchHashes
        }
        
        guard let hashesSize = hashes.first?.count else { return }
        
        var hashBytes = [UInt8]()
        for slice in hashes {
            if slice.count != hashesSize {
                throw TangemException.notIdenticalHashesLength
            }
            hashBytes.append(contentsOf: slice)
        }
        
        let pin2Bytes = pin2.sha256().data(using: String.Encoding.utf8, allowLossyConversion: true)!.bytes
        
        let transactionOutHashSizeBytes = [hashesSize.byte]
        
        let tlvData = [
            CardTLV(.pin2, value: pin2Bytes),
            CardTLV(.transactionOutHashSize, value: transactionOutHashSizeBytes),
            CardTLV(.transactionOutHash, value: hashBytes)]
        
        let commandApdu = CommandApdu(with: .sign, tlv: tlvData)
    }
    
}
