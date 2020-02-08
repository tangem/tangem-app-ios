////
////  CardSignSession.swift
////  TangemKit
////
////  Created by [REDACTED_AUTHOR]
////  Copyright © 2019 Smart Cash AG. All rights reserved.
////
//
//import UIKit
//#if canImport(CoreNFC)
//import CoreNFC
//#endif
//
//public enum CardSignError: Error {
//    case missingIssuerSignature
//    case nfcError(error: Error)
//    case emptyDataToSign
//    case allHashesLengthMustBeEqual
//    case failedBuldDataToSign
//}
//
//
//[REDACTED_USERNAME](iOS 13.0, *)
//public class CardSignSession: CardSession {
//    private let cardId: String
//    private let supportedSignMethods: [SignMethod]
//    private let issuerSignature: Data?
//    private var signApdu: NFCISO7816APDU?
//
//    public init(cardId: String, supportedSignMethods: [SignMethod], issuerSignature: Data? = nil, completion: @escaping (CardSessionResult<[CardTag : CardTLV]>) -> Void) {
//        self.cardId = cardId
//        self.issuerSignature = issuerSignature
//        self.supportedSignMethods = supportedSignMethods
//        super.init(completion: completion)
//    }
//    
//    public func start(dataToSign: [Data]) {
//        guard let hashSize = dataToSign.first?.count else {
//            completion(.failure(CardSignError.emptyDataToSign))
//            return
//        }
//        
//        var flattenHashes = [UInt8]()
//        flattenHashes.reserveCapacity(hashSize*dataToSign.count)
//        
//        for data in dataToSign {
//            guard data.count == hashSize else {
//                completion(.failure(CardSignError.allHashesLengthMustBeEqual))
//                return
//            }
//            
//            flattenHashes.append(contentsOf: data.bytes)
//        }
//        
//        guard let signApdu = buildSignApdu(Data(flattenHashes), hashSize: hashSize) else {
//            self.completion(.failure(CardSignError.failedBuldDataToSign))
//            return
//        }
//        
//        self.signApdu = signApdu
//        self.start()
//    }
//    
//    func buildSignApdu(_ dataToSign: Data, hashSize: Int) -> NFCISO7816APDU? {
//        let cardIdData = cardId.asciiHexToData()!
//        let hSize = [UInt8(hashSize)]
//        
//        var tlvData = [
//            CardTLV(.pin, value: "000000".sha256().asciiHexToData()),
//            CardTLV(.cardId, value: cardIdData),
//            CardTLV(.pin2, value: "000".sha256().asciiHexToData()),
//            CardTLV(.transactionOutHashSize, value: hSize),
//            CardTLV(.transactionOutHash, value: dataToSign.bytes)]
//        
//        if let keys = terminalKeysManager.getKeys(),
//            let signedData = CryptoUtils.sign(dataToSign.sha256(), with: keys.privateKey) {
//            tlvData.append(CardTLV(.terminalTransactionSignature, value: signedData.bytes))
//            tlvData.append(CardTLV(.terminalPublicKey, value: keys.publicKey.bytes))
//        }
//        
//        if supportedSignMethods.contains(.signHashValidatedByIssuer) {
//            if let issuerSignature = issuerSignature {
//                tlvData.append(CardTLV(.issuerTxSignature, value: Array(issuerSignature)))
//            } else {
//                if !supportedSignMethods.contains(.signHashValidatedByIssuer) {
//                    completion(.failure(CardSignError.missingIssuerSignature))
//                    return nil
//                }
//            }
//        }
//        
//        let commandApdu = CommandApdu(with: .sign, tlv: tlvData)
//        let signApduBytes = commandApdu.buildCommand()
//        let signApdu = NFCISO7816APDU(data: Data(bytes: signApduBytes))!
//        return signApdu
//    }
//    
//    override func onTagConnected() {
//        sendCardRequest(apdu: signApdu!) {[weak self] signResult in
//             guard let self = self else { return }
//            
//            self.readerSession?.alertMessage = Localizations.nfcAlertSignCompleted
//            self.invalidate(errorMessage: nil)
//            self.completion(.success(signResult))
//        }
//    }
//}
