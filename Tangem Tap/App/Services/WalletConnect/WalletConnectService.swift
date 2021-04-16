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
import SwiftUI
import web3swift

protocol WalletConnectChecker: class {
    var isServiceBusy: CurrentValueSubject<Bool, Never> { get }
    func containSession(for wallet: WalletInfo) -> Bool
}

protocol WalletConnectSessionController: WalletConnectChecker {
    var sessionsPublisher: Published<[WalletConnectSession]>.Publisher { get }
    var error: PassthroughSubject<Error, Never> { get }
    func disconnectSession(at index: Int)
    func handle(url: String) -> Bool
}

protocol WalletConnectHandlerDelegate: class {
    func send(_ response: Response)
    func sendReject(for request: Request)
}

protocol WalletConnectHandlerDataSource: class {
    var server: Server! { get }
    func session(for request: Request, address: String) -> WalletConnectSession?
}

class WalletConnectService: ObservableObject {
    var isServiceBusy: CurrentValueSubject<Bool, Never> = .init(false)
    
    var error: PassthroughSubject<Error, Never> = .init()
    
    @Published private(set) var sessions: [WalletConnectSession] = .init()
    var sessionsPublisher: Published<[WalletConnectSession]>.Publisher { $sessions }
    
    private(set) var server: Server!
    
    fileprivate var wallet: WalletInfo? = nil
    private let sessionsKey = "wc_sessions"
    
    init(assembly: Assembly, tangemSdk: TangemSdk, scannedCardsRepository: ScannedCardsRepository) {
        server = Server(delegate: self)
        server.register(handler: PersonalSignHandler(tangemSdk: tangemSdk, delegate: self, dataSource: self))
        server.register(handler: SignTransactionHandler(tangemSdk: tangemSdk, delegate: self, dataSource: self))
        server.register(handler: SendTransactionHandler(dataSource: self, delegate: self, assembly: assembly, scannedCardsRepo: scannedCardsRepository))
    }
    
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
        let decoder = JSONDecoder()
        if let oldSessionsObject = UserDefaults.standard.object(forKey: sessionsKey) as? Data {
            sessions = (try? decoder.decode([WalletConnectSession].self, from: oldSessionsObject)) ?? []
            sessions.forEach {
                do {
                    try server.reconnect(to: $0.session)
                } catch {
                    self.error.send(error)
                    print("Server did fail to reconnect")
                }
            }
        }
    }
    
    private func connect(to url: WCURL) {
        do {
            isServiceBusy.send(true)
            try server.connect(to: url)
        } catch {
            isServiceBusy.send(false)
            self.error.send(error)
            print("Server did fail to connect")
            return
        }
    }
    
    private func save() {
        let encoder = JSONEncoder()
        if let sessionsData = try? encoder.encode(sessions) {
            UserDefaults.standard.set(sessionsData, forKey: sessionsKey)
        }
    }
}

extension WalletConnectService: WalletConnectHandlerDataSource {
    func session(for request: Request, address: String) -> WalletConnectSession? {
        sessions.first(where: { $0.wallet.address.lowercased() == address.lowercased() && $0.session.url.topic == request.url.topic })
    }
}

extension WalletConnectService: WalletConnectHandlerDelegate {
    func send(_ response: Response) {
        server.send(response)
    }
    
    func sendReject(for request: Request) {
        server.send(.reject(request))
    }
}

extension WalletConnectService: WalletConnectChecker {
    func containSession(for wallet: WalletInfo) -> Bool {
        sessions.contains(where: { $0.wallet == wallet })
    }
}

extension WalletConnectService: WalletConnectSessionController {
    func disconnectSession(at index: Int) {
        guard index < sessions.count else { return }
        
        let session = sessions[index]
        do {
            try server.disconnect(from: session.session)
        } catch {
            print(error)
        }
        
        sessions.remove(at: index)
        save()
    }
}

extension WalletConnectService: CardDelegate {
    func didScan(_ card: Card) {
        if let cid = card.cardId,
           let wallet = card.wallets.first(where: { $0.curve == .secp256k1 }),
           let walletPublicKey = wallet.publicKey {
            self.wallet = WalletInfo(cid: cid,
                                     walletPublicKey: walletPublicKey,
                                     isTestnet: card.isTestnet ?? false)
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
        isServiceBusy.send(false)
        error.send(WalletConnectServiceError.failedToConnect)
    }
    
    func server(_ server: Server, shouldStart session: Session, completion: @escaping (Session.WalletInfo) -> Void) {
        guard let wallet = self.wallet else {
            completion(rejectedResponse)
            return
        }
        
        let peerMeta = session.dAppInfo.peerMeta
        var message = "Request to start a session for\n\(peerMeta.name)\n\nURL: \(peerMeta.url)"
        if let description = peerMeta.description, !description.isEmpty {
            message += "\n\n" + description
        }
        let onAccept = {
            self.sessions.filter {
                $0.wallet == wallet &&
                    $0.session.dAppInfo.peerMeta.url == session.dAppInfo.peerMeta.url
                    && $0.session.dAppInfo.peerMeta.name == session.dAppInfo.peerMeta.name
            }.forEach { try? server.disconnect(from: $0.session) }
            completion(Session.WalletInfo(approved: true,
                                          accounts: [wallet.address],
                                          chainId: wallet.chainId,
                                          peerId: UUID().uuidString,
                                          peerMeta: self.walletMeta))
        }
        DispatchQueue.main.async {
            UIApplication.modalFromTop(WalletConnectUIBuilder.makeAlert(for: .establishSession,
                                                                        message: message,
                                                                        onAcceptAction: onAccept,
                                                                        isAcceptEnabled: true,
                                                                        onReject: { completion(self.rejectedResponse) }))
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
        isServiceBusy.send(false)
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
        handle(url: url.absoluteString)
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
