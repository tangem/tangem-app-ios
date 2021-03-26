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

class WalletConnectService: ObservableObject {
    weak var tangemSdk: TangemSdk!
    var error: PassthroughSubject<Error, Never> = .init()
    
    @Published var sessions: [String: SessionData] = [:]
    
    var chainId: Int {
        isTestnet ? 4 : 1
    }
    
    var isEnabled: Bool {
        server != nil
    }
    
    private var server: Server? = nil
    private var sessionsKey = ""
    private var cid: String = ""
    private var address: String = ""
    private var isTestnet: Bool = false
    
    func start(for cid: String, walletPublicKey: Data, isTestnet: Bool) {
        self.cid = cid
        self.isTestnet = isTestnet
        self.sessionsKey = "wc_sessions_\(cid)"
        self.address = Blockchain.ethereum(testnet: isTestnet).makeAddresses(from: walletPublicKey, with: nil).first!.value
        
        server = Server(delegate: self)
        server!.register(handler: PersonalSignHandler(server: server!, tangemSdk: tangemSdk, address: address, walletPublicKey: walletPublicKey))
        server!.register(handler: SignTransactionHandler(server: server!, tangemSdk: tangemSdk, address: address, walletPublicKey: walletPublicKey, chainId: self.chainId))
        restore()
    }
    
    func stop() {
        cid = ""
        address = ""
        server = nil
        sessions = [:]
    }
    
    func disconnect(from sessionKey: String) {
        do {
            if let session = sessions[sessionKey]?.session {
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
    
    private func save() {
        let sessionsToSave = Dictionary(uniqueKeysWithValues: sessions.map { ($0.key, $0.value.session) })
        if let sessionsData = try? JSONEncoder().encode(sessionsToSave) {
            UserDefaults.standard.set(sessionsData, forKey: sessionsKey)
        }
    }
    
    private func restore() {
        if let oldSessionsObject = UserDefaults.standard.object(forKey: sessionsKey) as? Data,
           let sessions = try? JSONDecoder().decode([String:Session].self, from: oldSessionsObject) {
            self.sessions = Dictionary(uniqueKeysWithValues: sessions.map { ($0.key, SessionData(session: $0.value, status: .disconnected)) })
            self.sessions.values.forEach {
                do {
                    try server!.reconnect(to: $0.session)
                } catch {
                    self.error.send(error)
                    print("Server did fail to reconnect")
                    return
                }
            }
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
                                            chainId: self.chainId,
                                            peerId: UUID().uuidString,
                                            peerMeta: walletMeta)
        
        DispatchQueue.main.async {
            UIAlertController.showShouldStart(from: UIApplication.shared.topViewController!,
                                              clientName: session.dAppInfo.peerMeta.name,
                                              onStart: {
                completion(walletInfo)
            }, onClose: {
                completion(Session.WalletInfo(approved: false,
                                              accounts: [],
                                              chainId: self.chainId,
                                              peerId: "",
                                              peerMeta: walletMeta))
            })
        }
    }
    
    func server(_ server: Server, didConnect session: Session) {
        let key = self.key(for: session)
        let shouldSave = !sessions.keys.contains(key)
        sessions[key] = SessionData(session: session, status: .connected)
        if shouldSave {
           save()
        }
    }
    
    func server(_ server: Server, didDisconnect session: Session) {
        let key = self.key(for: session)
        sessions[key] = nil
        save()
    }
    
    func key(for session: Session) -> String {
        return "session_\(session.dAppInfo.peerMeta.name)"
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

fileprivate protocol BaseHandler: RequestHandler {
    var server: Server {get}
    var tangemSdk: TangemSdk {get}
    var walletPublicKey: Data {get}
    
    func askToSign(request: Request, message: String, sign: @escaping (_ completion: @escaping (String?) -> Void) -> Void)
}

fileprivate extension BaseHandler {
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

fileprivate class PersonalSignHandler: BaseHandler {
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

fileprivate class SignTransactionHandler: BaseHandler {
    let server: Server
    let tangemSdk: TangemSdk
    let walletPublicKey: Data
    
    private let address: String
    private let chainId: Int
    
    init(server: Server, tangemSdk: TangemSdk, address: String, walletPublicKey: Data, chainId: Int) {
        self.server = server
        self.tangemSdk = tangemSdk
        self.address = address
        self.walletPublicKey = walletPublicKey
        self.chainId = chainId
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
                self.sign(data: hexData) {[weak self] result in
                    guard let self = self else { return }
                    
                    switch result {
                    case .failure(let error):
                        print(error)
                        completion(nil)
                    case .success(let sig):
                        let str =  "0x" + sig.r.asHexString() + sig.s.asHexString() + String(sig.v.toInt() + 27 + self.chainId * 2 + 8, radix: 16)
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

fileprivate extension Response {
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


struct SessionData {
    let session: Session
    var status: SessionStatus
}

enum SessionStatus {
    case disconnected
    case connecting
    case connected
}
