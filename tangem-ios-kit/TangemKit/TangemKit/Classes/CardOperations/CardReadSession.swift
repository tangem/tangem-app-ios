////
////  CardReadOperation.swift
////  TangemKit
////
////  Created by [REDACTED_AUTHOR]
////  Copyright © 2019 Smart Cash AG. All rights reserved.
////
//
//import Foundation
//#if canImport(CoreNFC)
//import CoreNFC
//#endif
//
//[REDACTED_USERNAME](iOS 13.0, *)
//public class CardReadSession: CardSession {
//    private var readHandler: () -> Void
//    public init(completion: @escaping (CardSessionResult<[CardTag : CardTLV]>) -> Void, readHandler: @escaping () -> Void) {
//        self.readHandler = readHandler
//        super.init(completion: completion)
//    }
//
//    private func buildReadApdu() -> NFCISO7816APDU {
//        var tlvData = [CardTLV(.pin, value: "000000".sha256().asciiHexToData())]
//        if let keys = terminalKeysManager.getKeys() {
//            tlvData.append(CardTLV(.terminalPublicKey, value: Array(keys.publicKey)))
//        }
//
//        let commandApdu = CommandApdu(with: .read, tlv: tlvData)
//        let signApduBytes = commandApdu.buildCommand()
//        let apdu = NFCISO7816APDU(data: Data(bytes: signApduBytes))!
//        return apdu
//    }
//
//    private func buildCheckWalletApdu(with challenge: [UInt8], cardId: [UInt8]) -> NFCISO7816APDU {
//        let tlvData = [CardTLV(.pin, value: "000000".sha256().asciiHexToData()),
//                       CardTLV(.cardId, value: cardId),
//                       CardTLV(.challenge, value: challenge)]
//        let commandApdu = CommandApdu(with: .checkWallet, tlv: tlvData)
//        let signApduBytes = commandApdu.buildCommand()
//        let apdu = NFCISO7816APDU(data: Data(bytes: signApduBytes))!
//        return apdu
//    }
//
//    private func verifyWallet(readResult: [CardTag : CardTLV],
//                              checkWalletResult: [CardTag : CardTLV],
//                              challenge: [UInt8]) -> Bool {
//
//        guard let curveId = readResult[.curveId]?.value?.utf8String,
//            let curve = EllipticCurve(rawValue: curveId),
//            let publicKey = readResult[.walletPublicKey]?.value,
//            let salt = checkWalletResult[.salt]?.value,
//            let signature = checkWalletResult[.signature]?.value else {
//                return false
//        }
//        let data = challenge + salt
//
//        switch curve {
//        case .secp256k1:
//            let message = data.sha256()
//            var vrfy: secp256k1_context = secp256k1_context_create(.SECP256K1_CONTEXT_VERIFY)!
//            var sig = secp256k1_ecdsa_signature()
//            var normalized = secp256k1_ecdsa_signature()
//            _ = secp256k1_ecdsa_signature_parse_compact(vrfy, &sig, signature)
//            _ = secp256k1_ecdsa_signature_normalize(vrfy, &normalized, sig)
//            var pubkey = secp256k1_pubkey()
//            _ = secp256k1_ec_pubkey_parse(vrfy, &pubkey, publicKey, 65)
//            let result = secp256k1_ecdsa_verify(vrfy, normalized, message, pubkey)
//            secp256k1_context_destroy(&vrfy)
//            return result
//        case .ed25519:
//            let message = data.sha512()
//            let result = Ed25519.verify(signature, message, publicKey)
//            return result
//        }
//    }
//
//
//    override func onTagConnected() {
//        let readApdu = buildReadApdu()
//        guard let challenge = CryptoUtils.getRandomBytes(count: 16) else {
//            invalidate(errorMessage: "Failed to generate challenge")
//            return
//        }
//
//        self.sendCardRequest(apdu: readApdu) {[weak self] readResult in
//            guard let self = self else { return }
//
//            guard let intStatus = readResult[.status]?.value?.intValue,
//                let status = CardStatus(rawValue: intStatus),
//                status == .loaded  else {
//                    self.invalidate(errorMessage: nil)
//                    self.completion(.success(readResult))
//                    return
//            }
//            self.readHandler()
//            let cardId = readResult[.cardId]?.value
//            let checkWalletApdu = self.buildCheckWalletApdu(with: challenge, cardId: cardId! )
//            self.sendCardRequest(apdu: checkWalletApdu) {[weak self] checkWalletResult in
//                guard let self = self else { return }
//
//                self.invalidate(errorMessage: nil)
//                let verifyed = self.verifyWallet(readResult: readResult, checkWalletResult: checkWalletResult, challenge: challenge)
//                if verifyed {
//                    self.completion(.success(readResult))
//                } else {
//                    self.completion(.failure("Card verification failed"))
//                }
//            }
//        }
//    }
//
//    override func slixDidRead(data: [CardTag : CardTLV]) {
//        self.completion(.success(data))
//    }
//}
