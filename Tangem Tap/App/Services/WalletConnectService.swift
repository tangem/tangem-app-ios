//
//  WalletConnectService.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import WalletConnectSwift
import Combine
import TangemSdk
import BlockchainSdk
import CryptoSwift

class WalletConnectService {
    static let chainId = 4 //mainNet: 1, testnet: 4
    
    weak var tangemSdk: TangemSdk!
    
    var isEnabled: Bool {
        !cid.isEmpty && !address.isEmpty
    }
    
    var connected: CurrentValueSubject<Bool, Never> = .init(false)
    var error: PassthroughSubject<Error, Never> = .init()
    
    private var server: Server? = nil
    private var session: Session? = nil
    private var sessionKey = ""
    private var cid: String = ""
    private var address: String = ""
    private var walletPublicKey: Data = Data()
    
    init() {}
    
    func start(for cid: String, address: String, walletPublicKey: Data) {
        self.cid = cid
        self.address = address
        self.walletPublicKey = walletPublicKey
        
        self.sessionKey = "wc_session_\(cid)"
        server = Server(delegate: self)
        server!.register(handler: PersonalSignHandler(server: server!, tangemSdk: tangemSdk, address: address, walletPublicKey: walletPublicKey))
        server!.register(handler: SignTransactionHandler(server: server!, tangemSdk: tangemSdk, address: address, walletPublicKey: walletPublicKey))
        if let oldSessionObject = UserDefaults.standard.object(forKey: sessionKey) as? Data,
           let session = try? JSONDecoder().decode(Session.self, from: oldSessionObject) {
            do {
                try server?.reconnect(to: session)
            } catch {
                self.error.send(error)
                print("Server did fail to reconnect")
                return
            }
        }
    }
    
    func stop() {
        cid = ""
        address = ""
        walletPublicKey = Data()
        server = nil
        session = nil
    }
    
    func disconnect() {
        do {
            if let session = session {
                try server?.disconnect(from: session)
            }
        } catch {
            self.error.send(error)
            print("Server did fail to disconnect")
            return
        }
    }
    
    private func connect(to url: WCURL) {
        do {
            try server?.connect(to: url)
        } catch {
            self.error.send(error)
            print("Server did fail to connect")
            return
        }
    }
}

extension WalletConnectService: ServerDelegate {
    func server(_ server: Server, didFailToConnect url: WCURL) {
        error.send(WalletConnectServiceError.failedToConnect)
    }
    
    func server(_ server: Server, shouldStart session: Session, completion: @escaping (Session.WalletInfo) -> Void) {
        let walletMeta = Session.ClientMeta(name: "Tangem Wallet",
                                            description: nil,
                                            icons: [],
                                            url: URL(string: "https://tangem.com")!)
        
        let walletInfo = Session.WalletInfo(approved: true,
                                            accounts: [address],
                                            chainId: WalletConnectService.chainId,
                                            peerId: UUID().uuidString,
                                            peerMeta: walletMeta)
        
        DispatchQueue.main.async {
            UIAlertController.showShouldStart(from: UIApplication.shared.topViewController!,
                                              clientName: session.dAppInfo.peerMeta.name,
                                              onStart: {
                completion(walletInfo)
            }, onClose: {
                self.connected.send(false)
                completion(Session.WalletInfo(approved: false,
                                              accounts: [],
                                              chainId: WalletConnectService.chainId,
                                              peerId: "",
                                              peerMeta: walletMeta))
            })
        }
    }
    
    func server(_ server: Server, didConnect session: Session) {
        self.session = session
        if let sessionData = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(sessionData, forKey: sessionKey)
        }
        connected.send(true)
    }
    
    func server(_ server: Server, didDisconnect session: Session) {
        UserDefaults.standard.removeObject(forKey: sessionKey)
        connected.send(false)
        self.session = nil
        self.server = nil
    }
}

extension WalletConnectService: URLHandler {
    func handle(url: URL) -> Bool {
        return handle(url: url.absoluteString)
    }
    
    func handle(url: String) -> Bool {
        guard let url = WCURL(url) else { return false }
        
        DispatchQueue.global().async {
            self.connect(to: url)
        }
        
        return true
    }
}

extension WalletConnectService {
    enum WalletConnectServiceError: Error {
        case failedToConnect
        case signFailed
    }
}





protocol BaseHandler: RequestHandler {
    var server: Server {get}
    var tangemSdk: TangemSdk {get}
    var walletPublicKey: Data {get}
    
    func askToSign(request: Request, message: String, sign: @escaping (_ completion: @escaping (String?) -> Void) -> Void)
}

extension BaseHandler {
    func askToSign(request: Request, message: String, sign: @escaping (_ completion: @escaping (String?) -> Void) -> Void) {
        let onSign = {
            sign { signature in
                DispatchQueue.global().async {
                    if let signature = signature {
                        self.server.send(.signature(signature, for: request))
                    } else {
                        self.server.send(.reject(request))
                    }
                }
            }
        }
            let onCancel = {
                self.server.send(.reject(request))
            }
            
            DispatchQueue.main.async {
                UIAlertController.showShouldSign(from: UIApplication.shared.topViewController!,
                                                 title: "Request to sign a message",
                                                 message: message,
                                                 onSign: onSign,
                                                 onCancel: onCancel)
            }
        }
    
    func sign(data: Data, completion: @escaping (Result<(v: Data, r: Data, s: Data), Error>) -> Void) {
        let hash = data.sha3(.keccak256)
        tangemSdk.sign(hashes: [hash]) {[weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                if let unmarshalledSig = Secp256k1Utils.unmarshal(secp256k1Signature: response.signature, hash: hash, publicKey: self.walletPublicKey) {
                    completion(.success(unmarshalledSig))
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

class PersonalSignHandler: BaseHandler {
    let server: Server
    let tangemSdk: TangemSdk
    let walletPublicKey: Data
    
    private let address: String
    
    init(server: Server, tangemSdk: TangemSdk, address: String, walletPublicKey: Data) {
        self.server = server
        self.tangemSdk = tangemSdk
        self.address = address
        self.walletPublicKey = walletPublicKey
    }
    
    func canHandle(request: Request) -> Bool {
        return request.method == "personal_sign"
    }

    func handle(request: Request) {
        do {
            let messageBytes = try request.parameter(of: String.self, at: 0)
            let address = try request.parameter(of: String.self, at: 1)

            guard address == self.address else {
                server.send(.reject(request))
                return
            }

            let decodedMessage = String(data: Data(hex: messageBytes), encoding: .utf8) ?? messageBytes

            askToSign(request: request, message: decodedMessage) { completion in
                let personalMessageData = self.personalMessageData(messageData: Data(hex: messageBytes))
                
                self.sign(data: personalMessageData) { result in
                    switch result {
                    case .failure(let error):
                        print(error)
                        completion(nil)
                    case .success(let sig):
                        completion("0x" + sig.r.toHexString() + sig.s.toHexString() + String(sig.v.toInt() + 27, radix: 16)) // v in [0, 1]
                    }
                }
            }
        } catch {
            server.send(.invalid(request))
            return
        }
    }

    private func personalMessageData(messageData: Data) -> Data {
        let prefix = "\u{19}Ethereum Signed Message:\n"
        let prefixData = (prefix + String(messageData.count)).data(using: .ascii)!
        return prefixData + messageData
    }
}

class SignTransactionHandler: BaseHandler {
    let server: Server
    let tangemSdk: TangemSdk
    let walletPublicKey: Data
    
    private let address: String
    
    init(server: Server, tangemSdk: TangemSdk, address: String, walletPublicKey: Data) {
        self.server = server
        self.tangemSdk = tangemSdk
        self.address = address
        self.walletPublicKey = walletPublicKey
    }
    
    func canHandle(request: Request) -> Bool {
        return request.method == "eth_signTransaction"
    }

    func handle(request: Request) {
        do {
            let transaction = try request.parameter(of: EthTransaction.self, at: 0)
            guard transaction.from == address else {
                self.server.send(.reject(request))
                return
            }

            askToSign(request: request, message: transaction.description) { completion in
                let hexData = Data(hex: transaction.data)
                self.sign(data: hexData) {result in
                    switch result {
                    case .failure(let error):
                        print(error)
                        completion(nil)
                    case .success(let sig):
                        let str =  "0x" + sig.r.asHexString() + sig.s.asHexString() + String(sig.v.toInt() + 27 + WalletConnectService.chainId * 2 + 8, radix: 16)
                        completion(str)
                    }
                }
            }
        } catch {
            self.server.send(.invalid(request))
        }
    }
}

fileprivate extension UIAlertController {
    func withCloseButton(title: String = "Close", onClose: (() -> Void)? = nil ) -> UIAlertController {
        addAction(UIAlertAction(title: title, style: .cancel) { _ in onClose?() } )
        return self
    }
    
    static func showShouldStart(from controller: UIViewController, clientName: String, onStart: @escaping () -> Void, onClose: @escaping (() -> Void)) {
        let alert = UIAlertController(title: "Request to start a session", message: clientName, preferredStyle: .alert)
        let startAction = UIAlertAction(title: "Start", style: .default) { _ in onStart() }
        alert.addAction(startAction)
        controller.present(alert.withCloseButton(onClose: onClose), animated: true)
    }
    
    static func showShouldSign(from controller: UIViewController, title: String, message: String, onSign: @escaping () -> Void, onCancel: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let startAction = UIAlertAction(title: "Sign", style: .default) { _ in onSign() }
        alert.addAction(startAction)
        controller.present(alert.withCloseButton(title: "Reject", onClose: onCancel), animated: true)
    }
}

extension Response {
    static func signature(_ signature: String, for request: Request) -> Response {
        return try! Response(url: request.url, value: signature, id: request.id!)
    }
}


fileprivate struct EthTransaction: Codable {
    let from: String // Required
    let to: String // Required
    let gas: String // Required
    let gasPrice: String // Required
    let value: String // Required
    let data: String // Required
    let nonce: String // Required
    
    var description: String {
        return """
        to: \(to),
        value: \(value),
        gasPrice: \(gasPrice),
        gas: \(gas),
        data: \(data),
        nonce: \(nonce)
        """
    }
}
