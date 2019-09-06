//
//  CardSignOperation.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
#if canImport(CoreNFC)
import CoreNFC
#endif

@available(iOS 13.0, *)
public enum CardSessionResult<T> {
    case success(T)
    case failure(Error)
}

@available(iOS 13.0, *)
public class CardSession: NSObject {
    
    private let instruction: Instruction
    private let completion: (CardSessionResult<[CardTag : CardTLV]>) -> Void
    
    private lazy var readerSession: NFCTagReaderSession = {
        let session = NFCTagReaderSession(pollingOption: .iso14443, delegate: self)!
        session.alertMessage = "Hold your iPhone near a Tangem card"
        return session
    }()
    
    public init(instruction: Instruction, completion: @escaping (CardSessionResult<[CardTag : CardTLV]>) -> Void) {
        self.instruction = instruction
        self.completion = completion
    }
    deinit {
        print("CardSession deinit")
    }
    
    public func start() {
        readerSession.begin()
    }
    
    private func buildApdu() -> NFCISO7816APDU {
        let tlvData = buildTLV()
        let commandApdu = CommandApdu(with: instruction, tlv: tlvData)
        let signApduBytes = commandApdu.buildCommand()
        let apdu = NFCISO7816APDU(data: Data(bytes: signApduBytes))!
        return apdu
    }
    
    private func buildTLV() -> [CardTLV] {
        switch instruction {
        case .read:
            return [
                CardTLV(.pin, value: "000000".sha256().asciiHexToData()),
                CardTLV(.pin2, value: "000".sha256().asciiHexToData())]
        default:
            fatalError("Unsupported instruction")
        }
    }
}


@available(iOS 13.0, *)
extension CardSession: NFCTagReaderSessionDelegate {
    public func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        print("CardSession active")
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        if let nfcError = error as? NFCReaderError,
            nfcError.code != .readerSessionInvalidationErrorUserCanceled {
            completion(.failure(error))
        }
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        if case let .iso7816(tag7816) = tags.first {
            let nfcTag = tags.first!
            session.connect(to: nfcTag) {[unowned self] error in
                guard error == nil else {
                    session.invalidate(errorMessage: error!.localizedDescription)
                    return
                }
                
                let apdu = self.buildApdu()
                tag7816.sendCommand(apdu: apdu) {[unowned self] (data, sw1, sw2, apduError) in
                    guard apduError == nil else {
                        session.alertMessage = "Hold your iPhone near a Tangem card"
                        session.restartPolling()
                        return
                    }
                    
                    let respApdu = ResponseApdu(with: data, sw1: sw1, sw2: sw2)
                    if let cardState = respApdu.state {
                        switch cardState {
                        case .processCompleted:
                            session.invalidate()
                            self.completion(.success(respApdu.tlv))
                        default:
                            session.invalidate(errorMessage: cardState.localizedDescription)
                        }
                    } else {
                        session.invalidate(errorMessage: "Unknown card state: \(sw1) \(sw2)")
                    }
                    
                }
            }
        }
    }
    
    
}
