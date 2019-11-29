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
    case cancelled
}

@available(iOS 13.0, *)
public class CardSession: NSObject {
    fileprivate static let maxRetryCount = 10
    private var retryCount = CardSession.maxRetryCount
    var readerSession: NFCTagReaderSession?
    let completion: (CardSessionResult<[CardTag : CardTLV]>) -> Void
    lazy var terminalKeysManager:TerminalKeysManager = {
        let manager = TerminalKeysManager()
        return manager
    }()
    private lazy var delayFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = .second
        return formatter
    }()
    
    private var errorTimeoutTimer: TangemTimer!
    private var sessionTimer: TangemTimer!
    private var tagTimer: TangemTimer!
    private var invalidateByUser: Bool = false
    private var cancelled: Bool = false
    private var tag: NFCISO7816Tag?
    private var requestTimestamp: Date?
    
    public private(set) var isBusy: Bool = false
    
    func stopTimers() {
        TangemTimer.stopTimers([sessionTimer, tagTimer, errorTimeoutTimer])
    }
    
    func timerTimeout() {
        guard let session = self.readerSession,
            session.isReady  else { return }
        
        session.invalidate(errorMessage: Localizations.nfcSessionTimeout)
    }
    
    public init(completion: @escaping (CardSessionResult<[CardTag : CardTLV]>) -> Void) {
       self.completion = completion
        super.init()
        errorTimeoutTimer = TangemTimer(timeInterval: 5.0, completionHandler: { [weak self] in
            self?.isBusy = false
            self?.readerSession?.invalidate()
            self?.completion(.failure(Localizations.nfcStuckError))
        })
        sessionTimer = TangemTimer(timeInterval: 52.0, completionHandler: timerTimeout)
        tagTimer = TangemTimer(timeInterval: 18.0, completionHandler: timerTimeout)
    }
    
    public func start() {
        isBusy = true
        invalidateByUser = false
        readerSession = NFCTagReaderSession(pollingOption: .iso14443, delegate: self)!
        readerSession!.alertMessage = Localizations.nfcAlertDefault
        readerSession!.begin()
        errorTimeoutTimer.start()
    }
    
    func sendCardRequest(apdu: NFCISO7816APDU,
                         completionHandler:  @escaping ([CardTag : CardTLV]) -> Void) {
        requestTimestamp = Date()
        tag?.sendCommand(apdu: apdu) {[weak self](data, sw1, sw2, apduError) in
            guard let self = self else { return }
            
            print("receive response")
            guard !self.cancelled else {
                print("skip cancelled")
                return
            }
    
            if let _ = apduError {
                if let requestTimestamp = self.requestTimestamp,
                    requestTimestamp.distance(to: Date()) > 1.0 {
                    self.cancelled = true
                    print("invoke restart polling by timestamp")
                    self.retryCount = CardSession.maxRetryCount
                    self.restart()
                    return
                }
                
                if self.retryCount == 0 {
                    self.retryCount = CardSession.maxRetryCount
                    print("restart by retry")
                    self.restart()
                } else {
                    print("retry")
                    self.retryCount -= 1
                    self.sendCardRequest(apdu: apdu, completionHandler: completionHandler)
                }
                return
            }
            self.retryCount = CardSession.maxRetryCount
            let respApdu = ResponseApdu(with: data, sw1: sw1, sw2: sw2)
            if let cardState = respApdu.state {
                switch cardState {
                case .needPause:
                    if let remainingMilliseconds = respApdu.tlv[.pause]?.value?.intValue {
                        if let timeString = self.delayFormatter.string(from: TimeInterval(remainingMilliseconds/100)) {
                            self.readerSession?.alertMessage = Localizations.secondsLeft(timeString)
                        }
                    }
                    
                    if respApdu.tlv[.flash] != nil {
                        print("restart by flash")
                        self.restart()
                    } else {
                        self.sendCardRequest(apdu: apdu, completionHandler: completionHandler)
                    }
                case .processCompleted:
                    completionHandler(respApdu.tlv)
                default:
                    self.invalidate(errorMessage: cardState.localizedDescription)
                }
            } else {
                self.invalidate(errorMessage: "\(Localizations.unknownCardState): \(sw1) \(sw2)")
            }
        }
    }
    
    func onTagConnected() {}
    
    func invalidate(errorMessage: String?) {
        stopTimers()
        if let message = errorMessage {
            readerSession?.invalidate(errorMessage: message)
        } else {
            invalidateByUser = true
            readerSession?.invalidate()
        }
    }
    
    func restart() {
        DispatchQueue.main.async {
            self.tag = nil
            self.tagTimer.stop()
            self.readerSession?.restartPolling()
        }
    }
}


@available(iOS 13.0, *)
extension CardSession: NFCTagReaderSessionDelegate {
    public func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        errorTimeoutTimer.stop()
        sessionTimer.start()
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        stopTimers()
        self.isBusy = false
        self.cancelled = true
        self.tag = nil
        guard !invalidateByUser else {
            return
        }
        
        guard let nfcError = error as? NFCReaderError,
            nfcError.code != .readerSessionInvalidationErrorUserCanceled else {
                completion(.cancelled)
                return
        }
        
        completion(.failure(error))
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        print("didDetect tags")
        invalidateByUser = false
        cancelled = false
        requestTimestamp = nil
        if case let .iso7816(tag7816) = tags.first {
            let nfcTag = tags.first!
            session.connect(to: nfcTag) {[unowned self] error in
                guard error == nil else {
                    print("restart after error")
                    self.readerSession?.restartPolling()
                    return
                }
                self.tagTimer?.start()
                self.retryCount = CardSession.maxRetryCount
                self.tag = tag7816
                self.onTagConnected()
            }
        }
    }
}
