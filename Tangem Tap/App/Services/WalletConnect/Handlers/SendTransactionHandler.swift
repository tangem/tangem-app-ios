//
//  SendTransactionHandler.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import WalletConnectSwift
import BlockchainSdk
import TangemSdk
import Combine


class SendTransactionHandler: TangemWalletConnectRequestHandler {
    weak var delegate: WalletConnectHandlerDelegate?
    weak var dataSource: WalletConnectHandlerDataSource?
    unowned var assembly: Assembly
    unowned var scannedCardsRepo: ScannedCardsRepository
    
    private(set) var bag: Set<AnyCancellable> = []
    
    init(dataSource: WalletConnectHandlerDataSource, delegate: WalletConnectHandlerDelegate, assembly: Assembly, scannedCardsRepo: ScannedCardsRepository) {
        self.dataSource = dataSource
        self.assembly = assembly
        self.scannedCardsRepo = scannedCardsRepo
    }
    
    func canHandle(request: Request) -> Bool { request.method == "eth_sendTransaction" }

    func handle(request: Request) {
        do {
            let transaction = try request.parameter(of: WalletConnectEthTransaction.self, at: 0)
            
            guard let session = dataSource?.session(for: request, address: transaction.from) else {
                sendReject(for: request)
                return
            }
            
            askToMakeTx(in: session, for: request, ethTx: transaction)
        } catch {
            delegate?.send(.invalid(request))
        }
    }
    
    private func sendReject(for request: Request) {
        delegate?.sendReject(for: request)
    }
    
    private func askToMakeTx(in session: WalletConnectSession, for request: Request, ethTx: WalletConnectEthTransaction) {
        let wallet = session.wallet
        
        guard let card = scannedCardsRepo.cards[wallet.cid] else {
            sendReject(for: request)
            return
        }
        
        let blockchain = Blockchain.ethereum(testnet: wallet.isTestnet)
        let walletModels = assembly.makeWallets(from: CardInfo(card: card, artworkInfo: nil, twinCardInfo: nil), blockchains: [blockchain])
        
        guard
            let ethWalletModel = walletModels.first(where: { $0.wallet.address.lowercased() == ethTx.from.lowercased() }),
            let value = try? EthereumUtils.parseEthereumValue(ethTx.value),
            let gas = ethTx.gas?.hexToInteger ?? ethTx.gasLimit?.hexToInteger,
            let gasPrice = ethTx.gasPrice.hexToInteger
        else {
            sendReject(for: request)
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
                        let contractDataString = ethTx.data.drop0xPrefix
                        let wcTxData = Data(hexString: String(contractDataString))
                        tx.params = EthereumTransactionParams(data: wcTxData, gasLimit: gas, nonce: ethTx.nonce?.hexToInteger)
                        ethWalletModel.txSender.send(tx, signer: self.assembly.services.signer)
                            .sink { (completion) in
                                switch completion {
                                case .failure(let error):
                                    self.sendReject(for: request)
                                    self.presentOnMain(vc: error.alertController, delay: 0.1)
                                case .finished:
                                    break
                                }
                            } receiveValue: { (signResp) in
                                let vc = UIAlertController(title: "common_success".localized, message: "send_transaction_success".localized, preferredStyle: .alert)
                                vc.addAction(UIAlertAction(title: "common_ok".localized, style: .default, handler: nil))
                                self.presentOnMain(vc: vc, delay: 0.1)
                                
                                guard
                                    let sendedTx = ethWalletModel.wallet.transactions.last,
                                    let txHash = sendedTx.hash
                                else {
                                    self.sendReject(for: request)
                                    return
                                }
                                
                                self.delegate?.send(try! Response(url: request.url, value: "0x" + txHash, id: request.id!))
                            }
                            .store(in: &self.bag)

                    case .failure(let error):
                        self.presentOnMain(vc: error.alertController)
                    }
                }, isAcceptEnabled: (balance >= totalAmount), onReject: {
                    self.sendReject(for: request)
                })
                self.presentOnMain(vc: alert)
            }
            .store(in: &bag)
    }
    
    private func presentOnMain(vc: UIViewController, delay: Double = 0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            UIApplication.modalFromTop(vc)
        }
    }
}
