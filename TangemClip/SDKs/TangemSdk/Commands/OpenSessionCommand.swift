//
//  OpenSessionCommand.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation


struct OpenSessionResponse: JSONStringConvertible {
    let sessionKeyB: Data
    let uid: Data?
}

/// In case of encrypted communication, App should setup a session before calling any further command.
/// [OpenSessionCommand] generates secret session_key that is used by both host and card
/// to encrypt and decrypt commands’ payload.
class OpenSessionCommand: ApduSerializable {
    typealias CommandResponse = OpenSessionResponse
    
    private let sessionKeyA: Data
    
    init(sessionKeyA: Data) {
        self.sessionKeyA = sessionKeyA
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.sessionKeyA, value: sessionKeyA)
        
        let p2 = environment.encryptionMode == .strong ? EncryptionMode.strong.rawValue : EncryptionMode.fast.rawValue
        return CommandApdu(ins: Instruction.openSession.rawValue, p2: p2, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> OpenSessionResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        return OpenSessionResponse(sessionKeyB: try decoder.decode(.sessionKeyB),
                                   uid: try decoder.decodeOptional(.uid))
    }
}


protocol EncryptionHelper {
    var keyA: Data {get}
    func generateSecret(keyB: Data) -> Data?
}

class EncryptionHelperFactory {
    static func make(for mode: EncryptionMode) -> EncryptionHelper? {
        switch mode {
        case .fast:
            return FastEncryptionHelper()
        case .strong:
            return StrongEncryptionHelper()
        case .none:
            assertionFailure("Cannot make EncryptionHelper for EncryptionMode NONE")
            return nil
        }
    }
}

final class FastEncryptionHelper: EncryptionHelper {
    let keyA: Data
    
    init?() {
        do {
            keyA = try CryptoUtils.generateRandomBytes(count: 16)
        } catch {
            return nil
        }
    }
    
    func generateSecret(keyB: Data) -> Data? {
        return keyA + keyB
    }
}

final class StrongEncryptionHelper: EncryptionHelper {
    let keyA: Data
    
    private let keyPair: KeyPair
    
    init?() {
        if let keyPair = Secp256k1Utils.generateKeyPair() {
            self.keyPair = keyPair
            self.keyA = keyPair.publicKey
        } else {
            return nil
        }
    }
    
    func generateSecret(keyB: Data) -> Data? {
        return Secp256k1Utils.getSharedSecret(privateKey: keyPair.privateKey, publicKey: keyB)
    }
}
