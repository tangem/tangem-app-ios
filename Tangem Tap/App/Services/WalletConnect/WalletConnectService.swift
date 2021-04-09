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

protocol WalletConnectSessionChecker: class {
    func containSession(for wallet: WalletInfo) -> Bool
}

protocol WalletConnectSessionController: class {
    var sessions: [WalletConnectSession] { get }
    func disconnectSession(at index: Int) -> Bool
    func handle(url: String) -> Bool
}

class WalletConnectService: ObservableObject {
    weak var tangemSdk: TangemSdk!
    weak var walletManagerFactory: WalletManagerFactory!
    
    var error: PassthroughSubject<Error, Never> = .init()
    var connecting: PassthroughSubject<Bool, Never> = .init()
    
    @Published private(set) var sessions: [WalletConnectSession] = .init()
    
    internal lazy var server: Server = {
        let server = Server(delegate: self)
        server.register(handler: PersonalSignHandler(handler: self))
        server.register(handler: SignTransactionHandler(handler: self))
        return server
    }()
    
    fileprivate var wallet: WalletInfo? = nil
    private let sessionsKey = "wc_sessions"
 
    init() {}
    
    func disconnect(from session: Session) {
        do {
            if let session = sessions.first(where: { $0.session == session }) {
                try server.disconnect(from: session.session)
            }
        } catch {
            self.error.send(error)
            print("Server did fail to disconnect")
            return
        }
    }
    
    func restore() {
        if let oldSessionsObject = UserDefaults.standard.object(forKey: sessionsKey) as? Data {
            sessions = (try? JSONDecoder().decode([WalletConnectSession].self, from: oldSessionsObject)) ?? []
            sessions.forEach {
                do {
                    try server.reconnect(to: $0.session)
                } catch {
                    self.error.send(error)
                    print("Server did fail to reconnect")
                    return
                }
            }
        }
    }
    
    private func connect(to url: WCURL) {
        do {
            connecting.send(true)
            try server.connect(to: url)
        } catch {
            connecting.send(false)
            self.error.send(error)
            print("Server did fail to connect")
            return
        }
    }
    
    private func save() {
        if let sessionsData = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(sessionsData, forKey: sessionsKey)
        }
    }
}

extension WalletConnectService: WalletConnectSessionChecker {
    func containSession(for wallet: WalletInfo) -> Bool {
        sessions.contains(where: { $0.wallet == wallet })
    }
}

extension WalletConnectService: WalletConnectSessionController {
    func disconnectSession(at index: Int) -> Bool {
        guard index < sessions.count else { return true }
        
        let session = sessions[index]
        try! server.disconnect(from: session.session)
        return true
    }
}

extension WalletConnectService: CardDelegate {
    func didScan(_ card: Card) {
        if let cid = card.cardId,
           let wallet = card.wallets.first,
           let curve = wallet.curve, curve == .secp256k1,
           let walletPublicKey = wallet.publicKey {
            self.wallet = WalletInfo(cid: cid,
                                         walletPublicKey: walletPublicKey,
                                         isTestnet: card.isTestnet ?? false)
        } else {
            self.wallet = nil
        }
    }
}

extension WalletConnectService: ServerDelegate {
    private var walletMeta: Session.ClientMeta {
        Session.ClientMeta(name: "Tangem Wallet",
                           description: nil,
                           icons: [],
                           url: URL(string: "https://tangem.com")!)
    }
    
    private var rejectedResponse: Session.WalletInfo {
        Session.WalletInfo(approved: false,
                           accounts: [],
                           chainId: 0,
                           peerId: "",
                           peerMeta: walletMeta)
    }
    
    func server(_ server: Server, didFailToConnect url: WCURL) {
        connecting.send(false)
        error.send(WalletConnectServiceError.failedToConnect)
    }
    
    func server(_ server: Server, shouldStart session: Session, completion: @escaping (Session.WalletInfo) -> Void) {
        guard let wallet = self.wallet else {
            completion(rejectedResponse)
            return
        }
    
        DispatchQueue.main.async {
            UIAlertController.showShouldStart(from: UIApplication.shared.topViewController!,
                                              clientName: session.dAppInfo.peerMeta.name,
                                              onStart: {
                                                completion(Session.WalletInfo(approved: true,
                                                                              accounts: [wallet.address],
                                                                              chainId: wallet.chainId,
                                                                              peerId: UUID().uuidString,
                                                                              peerMeta: self.walletMeta))
                                              }, onClose: {
                                                completion(self.rejectedResponse)
                                              })
        }
    }
    
    func server(_ server: Server, didConnect session: Session) {
        if let sessionIndex = sessions.firstIndex(where: { $0.session == session }) { //reconnect
            sessions[sessionIndex].status = .connected
        } else {
            if let wallet = self.wallet { //new session only if wallet exists
                sessions.append(WalletConnectSession(wallet: wallet, session: session, status: .connected))
                save()
            }
        }
        connecting.send(false)
    }
    
    func server(_ server: Server, didDisconnect session: Session) {
        if let index = sessions.firstIndex(where: { $0.session == session }) {
            sessions.remove(at: index)
            save()
        }
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
extension WalletConnectService: SignHandler {
    func assertAddress(_ address: String) -> Bool {
        guard let wallet = self.wallet else {
            return false
        }
        
        return address.lowercased() == wallet.address.lowercased()
    }
    
    func askToSign(request: Request, message: String, dataToSign: Data) {
        let onSign = {
            self.sign(data: dataToSign) { res in
                DispatchQueue.global().async {
                    switch res {
                    case .success(let signature):
                        self.server.send(.signature(signature, for: request))
                    case .failure:
                        self.server.send(.invalid(request))
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
    
    func sign(data: Data, completion: @escaping (Result<String, Error>) -> Void) {
        guard let walletPublicKey = wallet?.walletPublicKey, let chainId = wallet?.chainId else {
            completion(.failure(WalletConnectService.WalletConnectServiceError.signFailed))
            return
        }
        
        let hash = data.sha3(.keccak256)
    
        
        
        tangemSdk.sign(hashes: [hash], walletPublicKey: walletPublicKey) {result in
            switch result {
            case .success(let response):
                if let unmarshalledSig = Secp256k1Utils.unmarshal(secp256k1Signature: response.signature,
                                                                  hash: hash,
                                                                  publicKey: walletPublicKey) {
                    
                    let strSig =  "0x" + unmarshalledSig.r.asHexString() + unmarshalledSig.s.asHexString() +
                        String(unmarshalledSig.v.toInt() + chainId * 2 + 8, radix: 16)
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

struct WalletInfo: Codable, Equatable {
    let cid: String
    let walletPublicKey: Data
    let isTestnet: Bool
    
    var address: String {
        Blockchain.ethereum(testnet: isTestnet).makeAddresses(from: walletPublicKey, with: nil).first!.value
    }
    
    var chainId: Int { isTestnet ? 4 : 1 }
    
    internal init(cid: String, walletPublicKey: Data, isTestnet: Bool) {
        self.cid = cid
        self.walletPublicKey = walletPublicKey
        self.isTestnet = isTestnet
    }
}

struct WalletConnectSession: Codable {
    let wallet: WalletInfo
    var session: Session
    var status: SessionStatus = .disconnected
    
    private enum CodingKeys: String, CodingKey {
        case wallet, session
    }
}

enum SessionStatus: Int, Codable {
    case disconnected
    case connecting
    case connected
}

extension Session: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.dAppInfo == rhs.dAppInfo && lhs.walletInfo == rhs.walletInfo
    }
}
