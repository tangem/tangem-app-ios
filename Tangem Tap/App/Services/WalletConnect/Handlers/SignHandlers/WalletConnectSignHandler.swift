//
//  WalletConnectSignHandler.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import WalletConnectSwift
import TangemSdk
import Combine

class WalletConnectSignHandler: TangemWalletConnectRequestHandler {
    weak var delegate: WalletConnectHandlerDelegate?
    weak var dataSource: WalletConnectHandlerDataSource?
    
    var action: WalletConnectAction {
        fatalError("WalletConnect action not specified")
    }
    
    private let signer: TangemSigner
    
    private var signerSubscription: AnyCancellable?
    
    init(signer: TangemSigner, delegate: WalletConnectHandlerDelegate, dataSource: WalletConnectHandlerDataSource) {
        self.signer = signer
        self.delegate = delegate
        self.dataSource = dataSource
    }
    
    func canHandle(request: Request) -> Bool {
        fatalError("Must be overriden by subclass")
    }
    
    func handle(request: Request) { }
    
    func askToSign(in session: WalletConnectSession, request: Request, message: String, dataToSign: Data) {
        let wallet = session.wallet
        
        let onSign: () -> Void = { [weak self] in
            self?.sign(with: wallet, data: dataToSign) { res in
                DispatchQueue.global().async {
                    guard let self = self else { return }
                    
                    switch res {
                    case .success(let signature):
                        self.delegate?.send(.signature(signature, for: request), for: self.action)
                    case .failure(let error):
                        self.delegate?.sendReject(for: request, with: error, for: self.action)
                    }
                }
            }
        }
        
        let alertMessage =  String(format: "wallet_connect_alert_sign_message".localized, TapCardIdFormatter(cid: session.wallet.cid).formatted(), message)
        DispatchQueue.main.async {
            UIApplication.modalFromTop(
                WalletConnectUIBuilder.makeAlert(for: .sign,
                                                 message: alertMessage,
                                                 onAcceptAction: onSign,
                                                 onReject: { self.delegate?.sendReject(for: request,
                                                                                       with: WalletConnectServiceError.cancelled,
                                                                                       for: self.action) })
            )
        }
    }
    
    func sign(with wallet: WalletInfo, data: Data, completion: @escaping (Result<String, Error>) -> Void) {
        let hash = data.sha3(.keccak256)
        
        signerSubscription = signer.sign(hash: hash, cardId: wallet.cid, walletPublicKey: wallet.walletPublicKey)
            .sink(receiveCompletion: { [weak self] (subsCompletion) in
                if case let .failure(error) = subsCompletion {
                    completion(.failure(error))
                }
                self?.signerSubscription = nil
            }, receiveValue: { (response) in
                if let unmarshalledSig = Secp256k1Utils.unmarshal(secp256k1Signature: response,
                                                                  hash: hash,
                                                                  publicKey: wallet.walletPublicKey) {
                    
                    let strSig =  "0x" + unmarshalledSig.r.asHexString() + unmarshalledSig.s.asHexString() +
                        unmarshalledSig.v.asHexString()
                    completion(.success(strSig))
                } else {
                    completion(.failure(WalletConnectServiceError.signFailed))
                }
            })
    }
    
}
