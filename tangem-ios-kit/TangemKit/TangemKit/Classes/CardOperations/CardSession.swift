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
    case pending(T)
    case failure(Error)
    case cancelled
}

@available(iOS 13.0, *)
public class CardSession: NSObject {
    fileprivate static let maxRetryCount = 20
    
    private var retryCount = CardSession.maxRetryCount
    private let completion: (CardSessionResult<[CardTag : CardTLV]>) -> Void
    private var readerSession: NFCTagReaderSession?
    private var cardHandled: Bool = false
    private lazy var terminalKeysManager:TerminalKeysManager = {
        let manager = TerminalKeysManager()
        return manager
    }()
    
   
    private var errorTimeoutTimer: Timer?
    private func startErrorTimeoutTimer() {
           DispatchQueue.main.async {
               self.errorTimeoutTimer?.invalidate()
               self.errorTimeoutTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(self.errorTimerTimeout), userInfo: nil, repeats: false)
           }
       }
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
    
    private func stopTimers() {
          DispatchQueue.main.async {
              self.sessionTimer?.invalidate()
              self.tagTimer?.invalidate()
              self.errorTimeoutTimer?.invalidate()
          }
      }
    
    public private(set) var isBusy: Bool = false
    
    @objc func timerTimeout() {
        guard let session = self.readerSession,
            session.isReady  else { return }
        
        session.invalidate(errorMessage: Localizations.nfcSessionTimeout)
    }
    
     @objc func errorTimerTimeout() {
        isBusy = false
        cardHandled = false
        readerSession?.invalidate()
        stopTimers()
        completion(.failure(Localizations.nfcStuckError))
    }
    
    public init(completion: @escaping (CardSessionResult<[CardTag : CardTLV]>) -> Void) {
        self.completion = completion
    }
    
    public func start() {
        isBusy = true
        cardHandled = false
        readerSession = NFCTagReaderSession(pollingOption: .iso14443, delegate: self)!
        readerSession!.alertMessage = Localizations.nfcAlertDefault
        readerSession!.begin()
        startErrorTimeoutTimer()
    }
    
    private func buildReadApdu() -> NFCISO7816APDU {
        var tlvData = [CardTLV(.pin, value: "000000".sha256().asciiHexToData())]
        if let keys = terminalKeysManager.getKeys() {
            tlvData.append(CardTLV(.terminalPublicKey, value: Array(keys.publicKey)))
        }
        
        let commandApdu = CommandApdu(with: .read, tlv: tlvData)
        let signApduBytes = commandApdu.buildCommand()
        let apdu = NFCISO7816APDU(data: Data(bytes: signApduBytes))!
        return apdu
    }
    
    private func buildCheckWalletApdu(with challenge: [UInt8], cardId: [UInt8]) -> NFCISO7816APDU {
        let tlvData = [CardTLV(.pin, value: "000000".sha256().asciiHexToData()),
                       CardTLV(.cardId, value: cardId),
                       CardTLV(.challenge, value: challenge)]
        let commandApdu = CommandApdu(with: .checkWallet, tlv: tlvData)
        let signApduBytes = commandApdu.buildCommand()
        let apdu = NFCISO7816APDU(data: Data(bytes: signApduBytes))!
        return apdu
    }
    
    private func verifyWallet(readResult: [CardTag : CardTLV],
                              checkWalletResult: [CardTag : CardTLV],
                              challenge: [UInt8]) -> Bool {
        
        guard let curveId = readResult[.curveId]?.value?.utf8String,
            let curve = EllipticCurve(rawValue: curveId),
            let publicKey = readResult[.walletPublicKey]?.value,
            let salt = checkWalletResult[.salt]?.value,
            let signature = checkWalletResult[.signature]?.value else {
                return false
        }
        let data = challenge + salt
        
        switch curve {
        case .secp256k1:
            let message = data.sha256()
            var vrfy: secp256k1_context = secp256k1_context_create(.SECP256K1_CONTEXT_VERIFY)!
            var sig = secp256k1_ecdsa_signature()
            var normalized = secp256k1_ecdsa_signature()
            _ = secp256k1_ecdsa_signature_parse_compact(vrfy, &sig, signature)
            _ = secp256k1_ecdsa_signature_normalize(vrfy, &normalized, sig)
            var pubkey = secp256k1_pubkey()
            _ = secp256k1_ec_pubkey_parse(vrfy, &pubkey, publicKey, 65)
            let result = secp256k1_ecdsa_verify(vrfy, normalized, message, pubkey)
            secp256k1_context_destroy(&vrfy)
            return result
        case .ed25519:
            let message = data.sha512()
            let result = Ed25519.verify(signature, message, publicKey)
            return result
        }
    }
    
    private func sendCardRequest(to tag7816: NFCISO7816Tag,
                                 apdu: NFCISO7816APDU,
                                 session: NFCTagReaderSession,
                                 completionHandler:  @escaping (CardSessionResult<[CardTag : CardTLV]>) -> Void) {
        tag7816.sendCommand(apdu: apdu) {[weak self](data, sw1, sw2, apduError) in
            guard let self = self else { return }
            
            if let _ = apduError {
                if self.retryCount == 0 {
                    session.restartPolling()
                } else {
                    self.retryCount -= 1
                    self.sendCardRequest(to: tag7816, apdu: apdu, session: session, completionHandler: completionHandler)
                }
                return
            }
            self.retryCount = CardSession.maxRetryCount
            let respApdu = ResponseApdu(with: data, sw1: sw1, sw2: sw2)
            self.stopTimers()
            if let cardState = respApdu.state {
                switch cardState {
                case .processCompleted:
                    completionHandler(.success(respApdu.tlv))
                default:
                    session.invalidate(errorMessage: cardState.localizedDescription)
                    completionHandler(.failure(cardState.localizedDescription))
                }
            } else {
                session.invalidate(errorMessage: "\(Localizations.unknownCardState): \(sw1) \(sw2)")
                completionHandler(.failure(Localizations.unknownCardState))
            }
        }
    }
}


@available(iOS 13.0, *)
extension CardSession: NFCTagReaderSessionDelegate {
    public func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        DispatchQueue.main.async {
            self.errorTimeoutTimer?.invalidate()
        }
        startSessionTimer()
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        guard !cardHandled else {
            return
        }
        
        self.isBusy = false
        stopTimers()
        guard let nfcError = error as? NFCReaderError,
            nfcError.code != .readerSessionInvalidationErrorUserCanceled else {
                completion(.cancelled)
                return
        }

        completion(.failure(error))
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        if case let .iso7816(tag7816) = tags.first {
            let nfcTag = tags.first!
            session.connect(to: nfcTag) {[unowned self] error in
                guard error == nil else {
                    session.invalidate(errorMessage: error!.localizedDescription)
                    self.stopTimers()
                    self.completion(.failure(error!))
                    return
                }
                self.startTagTimer()
                self.retryCount = CardSession.maxRetryCount
                
                let readApdu = self.buildReadApdu()
                guard let challenge = CryptoUtils.getRandomBytes(count: 16) else {
                    let error = "Failed to generate challenge"
                    session.invalidate(errorMessage: error)
                    self.isBusy = false
                    self.stopTimers()
                    self.completion(.failure(error))
                    return
                }
               
                self.sendCardRequest(to: tag7816, apdu: readApdu, session: session) { result in
            
                    switch result {
                    case .success(let readResult):
                        
                        guard let intStatus = readResult[.status]?.value?.intValue,
                            let status = CardStatus(rawValue: intStatus),
                            status == .loaded  else {
                                session.invalidate()
                                self.stopTimers()
                                self.completion(.success(readResult))
                                return
                        }
                        
                        let cardId = readResult[.cardId]?.value
                        let checkWalletApdu = self.buildCheckWalletApdu(with: challenge, cardId: cardId! )
                        self.completion(.pending(readResult))
                        self.sendCardRequest(to: tag7816, apdu: checkWalletApdu, session: session) {[unowned self] result in
                            switch result {
                            case .success(let checkWalletResult):
                                self.cardHandled = true
                                session.invalidate()
                                let verifyed = self.verifyWallet(readResult: readResult, checkWalletResult: checkWalletResult, challenge: challenge)
                                self.isBusy = false
                                if verifyed {
                                    self.completion(.success(readResult))
                                } else {
                                    self.completion(.failure("Card verification failed"))
                                }
                            default:
                                session.restartPolling()
                            }
                        }
                        break
                     default:
                         session.restartPolling()
                    }
                }
            }
        }
    }
    
}
