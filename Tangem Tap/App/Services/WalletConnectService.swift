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

class WalletConnectService {
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
    init() {}
    
    func start(for cid: String, address: String) {
        self.cid = cid
        self.address = address
        self.sessionKey = "wc_session_\(cid)"
        server = Server(delegate: self)
        server!.register(handler: PersonalSignHandler(for: UIApplication.shared.topViewController!, server: server!))
        server!.register(handler: SignTransactionHandler(for: UIApplication.shared.topViewController!, server: server!))
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
                                            chainId: 4,
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
                                              chainId: 4,
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
    }
}

class BaseHandler: RequestHandler {
    weak var controller: UIViewController!
    weak var sever: Server!
   
    init(for controller: UIViewController, server: Server) {
        self.controller = controller
        self.sever = server
    }

    func canHandle(request: Request) -> Bool {
        return false
    }

    func handle(request: Request) {
        // to override
    }

    func askToSign(request: Request, message: String, sign: @escaping () -> String) {
//        let onSign = {
//            let signature = sign()
//            self.sever.send(.signature(signature, for: request))
//        }
//        let onCancel = {
//            self.sever.send(.reject(request))
//        }
//        DispatchQueue.main.async {
//            UIAlertController.showShouldSign(from: self.controller,
//                                             title: "Request to sign a message",
//                                             message: message,
//                                             onSign: onSign,
//                                             onCancel: onCancel)
//        }
    }
}

class PersonalSignHandler: BaseHandler {
    override func canHandle(request: Request) -> Bool {
        return request.method == "personal_sign"
    }

    override func handle(request: Request) {
//        do {
//            let messageBytes = try request.parameter(of: String.self, at: 0)
//            let address = try request.parameter(of: String.self, at: 1)
//
//            guard address == privateKey.address.hex(eip55: true) else {
//                sever.send(.reject(request))
//                return
//            }
//
//            let decodedMessage = String(data: Data(hex: messageBytes), encoding: .utf8) ?? messageBytes
//
//            askToSign(request: request, message: decodedMessage) {
//                let personalMessageData = self.personalMessageData(messageData: Data(hex: messageBytes))
//                let (v, r, s) = try! self.privateKey.sign(message: .init(hex: personalMessageData.toHexString()))
//                return "0x" + r.toHexString() + s.toHexString() + String(v + 27, radix: 16) // v in [0, 1]
//            }
//        } catch {
//            sever.send(.invalid(request))
//            return
//        }
    }

    private func personalMessageData(messageData: Data) -> Data {
        let prefix = "\u{19}Ethereum Signed Message:\n"
        let prefixData = (prefix + String(messageData.count)).data(using: .ascii)!
        return prefixData + messageData
    }
}

class SignTransactionHandler: BaseHandler {
    override func canHandle(request: Request) -> Bool {
        return request.method == "eth_signTransaction"
    }

    override func handle(request: Request) {
//        do {
//            let transaction = try request.parameter(of: EthereumTransaction.self, at: 0)
//            guard transaction.from == privateKey.address else {
//                self.sever.send(.reject(request))
//                return
//            }
//
//            askToSign(request: request, message: transaction.description) {
//                let signedTx = try! transaction.sign(with: self.privateKey, chainId: 4)
//                let (r, s, v) = (signedTx.r, signedTx.s, signedTx.v)
//                return r.hex() + s.hex().dropFirst(2) + String(v.quantity, radix: 16)
//            }
//        } catch {
//            self.sever.send(.invalid(request))
//        }
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
}
