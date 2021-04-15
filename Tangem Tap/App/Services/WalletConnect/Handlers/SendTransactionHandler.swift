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
        self.delegate = delegate
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
        bag = []
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
            let gasLoader = ethWalletModel.walletManager as? EthereumGasLoader,
            let value = try? EthereumUtils.parseEthereumValue(ethTx.value),
            let gas = ethTx.gas?.hexToInteger ?? ethTx.gasLimit?.hexToInteger
        else {
            sendReject(for: request)
            return
        }
        
        let valueAmount = Amount(with: blockchain, address: wallet.address, type: .coin, value: value)
        ethWalletModel.update()
        
        // This zip attempting to load gas price and update wallet balance.
        // In some cases (ex. when swapping currencies on OpenSea) dApp didn't send gasPrice, that why we need to load this data from blockchain
        // Also we must identify that wallet failed to update balance.
        // If we couldn't get gasPrice and can't update wallet balance reject message will be send to dApp
        Publishers.Zip(getGasPrice(for: valueAmount, tx: ethTx, txSender: gasLoader, decimalCount: blockchain.decimalCount),
                       ethWalletModel
                        .$state
                        .setFailureType(to: Error.self)
                        .tryMap { state -> WalletModel.State in
                            switch state {
                            case .failed(let error):
                                throw error
                            case .noAccount(let message):
                                throw message
                            default:
                                return state
                            }
                        }
                        .filter { $0 == .idle })
            .sink { (completion) in
                if case .failure = completion {
                    self.sendReject(for: request)
                }
                self.bag = []
            } receiveValue: { (gasPrice, state) in
                let gasAmount = Amount(with: blockchain, address: wallet.address, type: .coin, value: Decimal(gas * gasPrice) / blockchain.decimalValue)
                let totalAmount = valueAmount + gasAmount
                let balance = ethWalletModel.wallet.amounts[.coin] ?? .zeroCoin(for: blockchain, address: ethTx.from)
                let dApp = session.session.dAppInfo
                let message: String = {
                    var m = ""
                    m += "Card: \(TapCardIdFormatter(cid: wallet.cid).formatted())\n"
                    
                    m += "Request to create transaction for \(dApp.peerMeta.name)\n\(dApp.peerMeta.url)\n\n"
                    m += "Amount: \(valueAmount.description)\n"
                    m += "Fee: \(gasAmount.description)\n"
                    m += "Total: \(totalAmount.description)\n"
                    m += "Balance: \(ethWalletModel.getBalance(for: .coin))"
                    if (balance < totalAmount) {
                        m += "\n\nCan't send transaction. Not enough funds."
                    }
                    return m
                }()
                let alert = WalletConnectUIBuilder.makeAlert(for: .sendTx, message: message, onAcceptAction: {
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
                                self.bag = []
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
                                print("\nSended transaction \(sendedTx) \ntxHash: \(txHash)\n\n")
                                
                                self.delegate?.send(try! Response(url: request.url, value: txHash, id: request.id!))
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
    
    private func getGasPrice(for amount: Amount, tx: WalletConnectEthTransaction, txSender: EthereumGasLoader, decimalCount: Int) -> AnyPublisher<Int, Error> {
        guard
            let gasPriceString = tx.gasPrice,
            let gasPrice = gasPriceString.hexToInteger
        else {
            return txSender.getGasPrice()
                .flatMap { (gasPrice) -> AnyPublisher<Int, Error> in
                    .justWithError(output: Int(gasPrice))
                }
                .eraseToAnyPublisher()
        }
        
        return .justWithError(output: gasPrice)
    }
    
    private func sendTxPublisher() {
        
    }
    
    private func presentOnMain(vc: UIViewController, delay: Double = 0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            UIApplication.modalFromTop(vc)
        }
    }
}
