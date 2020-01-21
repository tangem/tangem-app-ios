////
////  TangemSession.swift
////  Tangem
////
////  Created by [REDACTED_AUTHOR]
////
//
//import Foundation
//
//public enum TangemSessionError: Error, LocalizedError {
//    case readerSessionError(error: Error)
//    case payloadError
//    case locked
//    case userCancelled
//}
//
//public protocol TangemSessionDelegate: class {
//    
//    func tangemSessionDidRead(card: CardViewModel)
//    func tangemSessionDidFailWith(error: TangemSessionError)
//    
//}
//
//public class TangemSession {
//    
//    public var payload: Data?
//    
//    var isBusy: Bool {
//        if #available(iOS 13.0, *), payload == nil {
//            return readSession.isBusy
//        } else {
//            return scanner?.isBusy ?? false
//        }
//    }
//    
//    weak var delegate: TangemSessionDelegate?
//    var card: CardViewModel?
//    var scanner: CardScanner?
//    
//    [REDACTED_USERNAME](iOS 13.0, *)
//    lazy var readSession: CardReadSession = {
//        let session = CardReadSession(completion: { [weak self] result in
//            switch result {
//            case .success (let tlv):
//                let card = CardViewModel(tags: Array(tlv.values))
//                card.genuinityState = .genuine
//                DispatchQueue.main.async {
//                    self?.delegate?.tangemSessionDidRead(card: card)
//                }
//            case .failure(let error):
//                DispatchQueue.main.async {
//                    self?.delegate?.tangemSessionDidFailWith(error: .readerSessionError(error:error))
//                }
//            case .cancelled:
//                DispatchQueue.main.async {
//                    self?.delegate?.tangemSessionDidFailWith(error: .userCancelled)
//                }
//            }
//        }) { [weak self] in
//            let card = CardViewModel()
//            card.genuinityState = .pending
//            DispatchQueue.main.async {
//                self?.delegate?.tangemSessionDidRead(card: card)
//            }
//        }
//        return session
//    }()
//    
//    
//    public init(payload: Data? = nil, delegate: TangemSessionDelegate) {
//        self.delegate = delegate
//        self.payload = payload
//    }
//    
//    public func invalidate() {
//        scanner?.invalidate()
//    }
//    
//    public func start() {
//        guard !isBusy else {
//            return
//        }
//        
//        if #available(iOS 13.0, *), payload == nil {
//            readSession.start()
//        } else {
//            startDoubleScanReadSession()
//        }
//    }
//    
//    private func startDoubleScanReadSession() {
//        scanner = CardScanner(payload: payload, completion: { [weak self] (result) in
//            DispatchQueue.main.async {
//                switch result {
//                case .pending(let card):
//                    self?.delegate?.tangemSessionDidRead(card: card)
//                case .finished(let card):
//                    self?.delegate?.tangemSessionDidRead(card: card)
//                case .readerSessionError(let nfcError):
//                    self?.delegate?.tangemSessionDidFailWith(error: .readerSessionError(error:nfcError))
//                case .locked:
//                    self?.delegate?.tangemSessionDidFailWith(error: .locked)
//                case .tlvError:
//                    self?.delegate?.tangemSessionDidFailWith(error: .payloadError)
//                case .cardChanged:
//                    self?.handleCardChanged()
//                }
//            }
//        })
//    }
//    
//    func handleCardChanged() {
//        guard !isBusy else {
//            return
//        }
//        
//        start()
//    }    
//}
