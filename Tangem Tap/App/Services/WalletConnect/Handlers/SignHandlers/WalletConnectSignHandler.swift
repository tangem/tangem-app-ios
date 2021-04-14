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

class WalletConnectSignHandler: TangemWalletConnectRequestHandler {
    weak var delegate: WalletConnectHandlerDelegate?
    weak var dataSource: WalletConnectHandlerDataSource?
    
    private let tangemSdk: TangemSdk
    
    init(tangemSdk: TangemSdk, delegate: WalletConnectHandlerDelegate, dataSource: WalletConnectHandlerDataSource) {
        self.tangemSdk = tangemSdk
        self.delegate = delegate
        self.dataSource = dataSource
    }
    
    func canHandle(request: Request) -> Bool {
        fatalError("Must be overriden by subclass")
    }
    
    func handle(request: Request) { }
    
    func askToSign(in session: WalletConnectSession, request: Request, message: String, dataToSign: Data) {
        let wallet = session.wallet
        
        let onSign = {
            self.sign(with: wallet, data: dataToSign) { res in
                DispatchQueue.global().async {
                    switch res {
                    case .success(let signature):
                        self.delegate?.send(.signature(signature, for: request))
                    case .failure:
                        self.delegate?.send(.invalid(request))
                    }
                }
            }
        }
        
        let onCancel: () -> Void = {
            self.delegate?.sendReject(for: request)
        }
        
        DispatchQueue.main.async {
            UIAlertController.showShouldSign(from: UIApplication.topViewController!,
                                             title: "Request to sign a message",
                                             message: message,
                                             onSign: onSign,
                                             onCancel: onCancel)
        }
    }
    
    func sign(with wallet: WalletInfo, data: Data, completion: @escaping (Result<String, Error>) -> Void) {
        let hash = data.sha3(.keccak256)
        
        tangemSdk.sign(hash: hash, walletPublicKey: wallet.walletPublicKey) {result in
            switch result {
            case .success(let response):
                if let unmarshalledSig = Secp256k1Utils.unmarshal(secp256k1Signature: response,
                                                                  hash: hash,
                                                                  publicKey: wallet.walletPublicKey) {
                    
                    let strSig =  "0x" + unmarshalledSig.r.asHexString() + unmarshalledSig.s.asHexString() +
                        String(unmarshalledSig.v.toInt() + wallet.chainId * 2 + 8, radix: 16)
                    completion(.success(strSig))
                } else {
                    completion(.failure(WalletConnectService.WalletConnectServiceError.signFailed))
                }
            case .failure(let error):
                print(error)
                completion(.failure(error))
            }
        }
    }
    
}
