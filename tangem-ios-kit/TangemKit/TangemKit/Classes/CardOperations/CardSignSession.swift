//
//  CardSignSession.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import UIKit
#if canImport(CoreNFC)
import CoreNFC
#endif

public enum CardSignError: Error {
    case missingIssuerSignature
    case nfcError(error: Error)
}

public enum CardSignSessionResult<T> {
    case success(T)
    case failure(CardSignError)
    case cancelled
}

enum NFCState {
    case active
    case signed
    case processing
    case none
}

@available(iOS 13.0, *)
public class CardSignSession: NSObject {
    private let completion: (CardSignSessionResult<[UInt8]>) -> Void
    private var readerSession: NFCTagReaderSession?
    private let cardId: String
    private let supportedSignMethods: [SignMethod]
    private let issuerSignature: Data?
    public  var isBusy: Bool {
        return state != .none
    }
    private let stateLockQueue = DispatchQueue(label: "Tangem.SignSession.stateLockQueue")
    private var _state: NFCState = .none
    var state: NFCState  {
        get {
            stateLockQueue.sync {
                return _state
            }
        }
        set {
            stateLockQueue.sync {
                _state = newValue
            }
        }
    }
    private var signApdu: NFCISO7816APDU?
    private var sessionTimer: Timer?
    private func startSessionTimer() {
        DispatchQueue.main.async {
            self.sessionTimer?.invalidate()
            self.sessionTimer = Timer.scheduledTimer(timeInterval: 59.0, target: self, selector: #selector(self.timerTimeout), userInfo: nil, repeats: false)
        }
    }
    
    private var tagTimer: Timer?
    private func startTagTimer() {
        DispatchQueue.main.async {
            self.tagTimer?.invalidate()
            self.tagTimer = Timer.scheduledTimer(timeInterval: 19.0, target: self, selector: #selector(self.timerTimeout), userInfo: nil, repeats: false)
        }
    }
    
    @objc func timerTimeout() {
        guard let session = self.readerSession,
            (state == .active || state == .processing)   else { return }
        
        if state == .processing {
            state = .none
            return
        }
        session.invalidate(errorMessage: Localizations.nfcSessionTimeout)
    }
    
    public init(cardId: String, supportedSignMethods: [SignMethod], issuerSignature: Data? = nil, completion: @escaping (CardSignSessionResult<[UInt8]>) -> Void) {
        self.completion = completion
        self.cardId = cardId
        self.issuerSignature = issuerSignature
        self.supportedSignMethods = supportedSignMethods
    }
    
    public func start(dataToSign: Data) {
        state = .active
        guard let signApdu = buildSignApdu(dataToSign) else {
            state = .none
            return
        }
        self.signApdu = signApdu
        readerSession = NFCTagReaderSession(pollingOption: .iso14443, delegate: self)!
        readerSession!.alertMessage = Localizations.nfcAlertDefault
        readerSession!.begin()
    }
    

    func buildSignApdu(_ dataToSign: Data) -> NFCISO7816APDU? {
        let cardIdData = cardId.asciiHexToData()!
        let hSize = [UInt8(dataToSign.count)]
        
        var tlvData = [
            CardTLV(.pin, value: "000000".sha256().asciiHexToData()),
            CardTLV(.cardId, value: cardIdData),
            CardTLV(.pin2, value: "000".sha256().asciiHexToData()),
            CardTLV(.transactionOutHashSize, value: hSize),
            CardTLV(.transactionOutHash, value: dataToSign.bytes)]
    
        
        if supportedSignMethods.contains(.signHashValidatedByIssuer) {
            if let issuerSignature = issuerSignature {
                 tlvData.append(CardTLV(.issuerTxSignature, value: Array(issuerSignature)))
            } else {
                if !supportedSignMethods.contains(.signHashValidatedByIssuer) {
                    completion(.failure(CardSignError.missingIssuerSignature))
                    return nil
                }
            }
        }
        
        let commandApdu = CommandApdu(with: .sign, tlv: tlvData)
        let signApduBytes = commandApdu.buildCommand()
        let signApdu = NFCISO7816APDU(data: Data(bytes: signApduBytes))!
        return signApdu
    }
    
    private func sendSignRequest(to tag: NFCISO7816Tag, with session: NFCTagReaderSession, _ apdu: NFCISO7816APDU) {
        tag.sendCommand(apdu: apdu) {[unowned self] (data, sw1, sw2, apduError) in
            guard apduError == nil else {
                session.alertMessage = Localizations.nfcAlertDefault
                session.restartPolling()
                return
            }
            self.state = .processing
            
            let respApdu = ResponseApdu(with: data, sw1: sw1, sw2: sw2)
            
            if let cardState = respApdu.state {
                switch cardState {
                case .needPause:
                    if let remainingMilliseconds = respApdu.tlv[.pause]?.value?.intValue {
                        self.readerSession?.alertMessage = "\(Localizations.dialogSecurityDelay): \(remainingMilliseconds/100) \(Localizations.secondsLeft)"
                    }
                
                    if respApdu.tlv[.flash] != nil {
                        self.readerSession?.restartPolling()
                    } else {
                        if self.state == .none {
                            session.invalidate(errorMessage: Localizations.nfcSessionTimeout)
                            return
                        }
                        self.sendSignRequest(to: tag, with: session, apdu)
                    }
                    
                case .processCompleted:
                    self.state = .signed
                    session.alertMessage = Localizations.nfcAlertSignCompleted
                    session.invalidate()
                    if let sign = respApdu.tlv[.signature]?.value {
                        self.state = .none
                        DispatchQueue.main.async {
                            self.completion(.success(sign))
                        }
                        return
                    }
                default:
                    session.invalidate(errorMessage: cardState.localizedDescription)
                }
            } else {
                session.invalidate(errorMessage: "\(Localizations.unknownCardState): \(sw1) \(sw2)")
            }
            
        }
    }
}


@available(iOS 13.0, *)
extension CardSignSession: NFCTagReaderSessionDelegate {
    public func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        startSessionTimer()
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        guard state != .signed else {
            return
        }
        state = .none
        DispatchQueue.main.async {
            guard let nfcError = error as? NFCReaderError,
                nfcError.code != .readerSessionInvalidationErrorUserCanceled else {
                      self.completion(.cancelled)
                      return
            }
            self.completion(.failure(CardSignError.nfcError(error: nfcError)))            
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
                
                self.startTagTimer()
                self.sendSignRequest(to: tag7816, with: session, self.signApdu!)
            }
        }
    }
    
}
