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
    var sessions: [WalletConnectSession] { get }
    func disconnectSession(at index: Int)
    func handle(url: String) -> Bool
}

class WalletConnectService: ObservableObject {
    weak var assembly: Assembly!
    weak var tangemSdk: TangemSdk!
    weak var walletManagerFactory: WalletManagerFactory!
    var txSigner: TransactionSigner!
    
    var isServiceBusy: CurrentValueSubject<Bool, Never> = .init(false)
    
    var error: PassthroughSubject<Error, Never> = .init()
    
    @Published private(set) var sessions: [WalletConnectSession] = .init()
    private var cards: [String:Card] = [:]
    
    private(set) lazy var server: Server = {
        let server = Server(delegate: self)
        server.register(handler: PersonalSignHandler(handler: self))
        server.register(handler: SignTransactionHandler(handler: self))
        server.register(handler: SendTransactionHandler(handler: self))
        return server
    }()
    
    fileprivate var wallet: WalletInfo? = nil
    private let sessionsKey = "wc_sessions"
    private let cardsKey = "scanned_cards"
    private var bag: Set<AnyCancellable> = []
 
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
        if let scannedCardsObj = UserDefaults.standard.object(forKey: cardsKey) as? Data {
            cards = (try? decoder.decode([String:Card].self, from: scannedCardsObj)) ?? [:]
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
        if let cardsData = try? encoder.encode(cards) {
            UserDefaults.standard.setValue(cardsData, forKey: cardsKey)
        }
    }
    
    private func sendReject(for request: Request) {
        server.send(.reject(request))
    }
    
    private func findSession(for address: String) -> WalletConnectSession? {
        sessions.first(where: { $0.wallet.address.lowercased() == address.lowercased() })
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
           let wallet = card.wallets.first,
           let curve = wallet.curve, curve == .secp256k1,
           let walletPublicKey = wallet.publicKey {
            self.wallet = WalletInfo(cid: cid,
                                         walletPublicKey: walletPublicKey,
                                         isTestnet: card.isTestnet ?? false)
            cards[cid] = card
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
        findSession(for: address) != nil
    }
    
    func askToSign(request: Request, address: String, message: String, dataToSign: Data) {
        guard let wallet = findSession(for: address)?.wallet else {
            sendReject(for: request)
            return
        }
        let onSign = {
            self.sign(with: wallet, data: dataToSign) { res in
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
            self.sendReject(for: request)
        }
        
        DispatchQueue.main.async {
            UIAlertController.showShouldSign(from: UIApplication.shared.topViewController!,
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

extension WalletConnectService: WCSendTxHandler {
    func askToMakeTx(request: Request, ethTx: EthTransaction) {
        guard let session = self.sessions.first(where: { $0.wallet.address.lowercased() == ethTx.from.lowercased() }) else {
            self.sendReject(for: request)
            return
        }
        
        let wallet = session.wallet
        let blockchain = Blockchain.ethereum(testnet: wallet.isTestnet)
        
        let contractDataString = ethTx.data.drop0xPrefix
        let wcTxData = Data(hexString: String(contractDataString))
        guard
            let card = cards[wallet.cid],
            let walletModels = assembly?.makeWallets(from: CardInfo(card: card, artworkInfo: nil, twinCardInfo: nil), blockchains: [blockchain]),
            let ethWalletModel = walletModels.first(where: { $0.wallet.address.lowercased() == ethTx.from.lowercased() }),
            let value = try? EthereumUtils.parseEthereumValue(ethTx.value),
            let gas = ethTx.gas.hexToInteger,
            let gasPrice = ethTx.gasPrice.hexToInteger
        else {
            self.sendReject(for: request)
            return
        }
        
        ethWalletModel.update()
        ethWalletModel.$state
            .sink { (state) in
                guard case .idle = state else { return }
                
                let valueAmount = Amount(with: blockchain, address: wallet.address, type: .coin, value: value)
                let gasAmount = Amount(with: blockchain, address: wallet.address, type: .coin, value: Decimal(gas * gasPrice) / blockchain.decimalValue)
                let totalAmount = valueAmount + gasAmount
                let balance = ethWalletModel.wallet.amounts[.coin] ?? .zeroCoin(for: blockchain, address: ethTx.from)
                let dApp = session.session.dAppInfo
                let message: String = {
                    var m = ""
                    m += "\(CardIdFormatter().formatted(cid: wallet.cid))\n"
                    
                    m += "Request to create transaction for \(dApp.peerMeta.name)\n\(dApp.peerMeta.url)\n"
                    m += "Amount: \(valueAmount.description)\n"
                    m += "Fee: \(gasAmount.description)\n"
                    m += "Total: \(totalAmount.description)\n"
                    m += "Balance: \(ethWalletModel.getBalance(for: .coin))"
                    if (balance < totalAmount) {
                        m += "\nCan't send transaction. Not enough funds."
                    }
                    return m
                }()
                let alert = WalletConnectUIBuilder.makeAlert(for: .sendTx, withTitle: "Wallet Connect", message: message, onAcceptAction: {
                    switch ethWalletModel.walletManager.createTransaction(amount: valueAmount, fee: gasAmount, destinationAddress: ethTx.to, sourceAddress: ethTx.from) {
                    case .success(var tx):
                        tx.params = EthereumTransactionParams(data: wcTxData, gasLimit: gas)
                        ethWalletModel.txSender.send(tx, signer: self.txSigner)
                            .sink { (completion) in
                                switch completion {
                                case .failure(let error):
                                    self.sendReject(for: request)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        UIApplication.modalFromTop(error.alertController)
                                    }
                                case .finished:
                                    break
                                }
                            } receiveValue: { (signResp) in
                                let vc = UIAlertController(title: "common_success".localized, message: "send_transaction_success".localized, preferredStyle: .alert)
                                vc.addAction(UIAlertAction(title: "common_ok".localized, style: .destructive, handler: nil))
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    UIApplication.modalFromTop(vc)
                                }
                                guard
                                    let sendedTx = ethWalletModel.wallet.transactions.last,
                                    let txHash = sendedTx.hash
                                else {
                                    self.sendReject(for: request)
                                    return
                                }
                                
                                self.server.send(try! Response(url: request.url, value: "0x" + txHash, id: request.id!))
                            }
                            .store(in: &self.bag)

                    case .failure(let error):
                        let vc = error.alertController
                        DispatchQueue.main.async {
                            UIApplication.modalFromTop(vc)
                        }
                    }
                }, isAcceptEnabled: (balance >= totalAmount), onReject: {
                    self.sendReject(for: request)
                })
                DispatchQueue.main.async {
                    UIApplication.modalFromTop(alert)
                }
            }
            .store(in: &bag)
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

extension StringProtocol {
    var drop0xPrefix: SubSequence { hasPrefix("0x") ? dropFirst(2) : self[...] }
    var hexToInteger: Int? { Int(drop0xPrefix, radix: 16) }
    var integerToHex: String { .init(Int(self) ?? 0, radix: 16) }
}
