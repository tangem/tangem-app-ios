//
//  Data+KeyUtils.swift
//  stellarsdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

extension Data {
    
    public func encodeEd25519PublicKey() throws -> String {
        return try encodeCheck(versionByte: .accountId)
    }
    
    public func encodeMuxedAccount() throws -> String {
        let muxed = try XDRDecoder.decode(MuxedAccountXDR.self, data:self)
        switch muxed {
        case .ed25519(_):
            return muxed.ed25519AccountId
        case .med25519(let mux):
            let data = try Data(bytes: XDREncoder.encode(mux))
            let result = try data.encodeMEd25519AccountId()
            return result.replacingOccurrences(of: "=", with: "")
        }
    }
    
    public func encodeMEd25519AccountId() throws -> String {
        return try encodeCheck(versionByte: .muxedAccountId)
    }
    
    public func encodeEd25519SecretSeed() throws -> String {
        return try encodeCheck(versionByte: .seed)
    }
    
    public func encodePreAuthTx() throws -> String {
        return try encodeCheck(versionByte: .preAuthTX)
    }
    
    public func encodeSha256Hash() throws -> String {
        return try encodeCheck(versionByte: .sha256Hash)
    }
    
    private func encodeCheck(versionByte:VersionByte) throws -> String {
        var versionByteRaw = versionByte.rawValue
        let versionByteData = Data(bytes: &versionByteRaw, count: MemoryLayout.size(ofValue: versionByte))
        let payload = NSMutableData(data: versionByteData)
        payload.append(Data(self.bytes))
        let checksumedData = (payload as Data).crc16Data()
        
        return checksumedData.base32EncodedString
    }
    
}
