//
//  WalletConnectTransactionBuilder.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine
import WalletConnectSwift

class WalletConnectTransactionHandler: TangemWalletConnectRequestHandler {
    unowned var assembly: Assembly
    unowned var scannedCardsRepo: ScannedCardsRepository
    unowned var delegate: WalletConnectHandlerDelegate?
    unowned var dataSource: WalletConnectHandlerDataSource?
    
    let signer: TangemSigner
    
    var action: WalletConnectAction { fatalError("Subclass must implement") }
    
    var bag: Set<AnyCancellable> = []
    
    init(signer: TangemSigner, delegate: WalletConnectHandlerDelegate, dataSource: WalletConnectHandlerDataSource, assembly: Assembly, scannedCardsRepo: ScannedCardsRepository) {
        self.assembly = assembly
        self.scannedCardsRepo = scannedCardsRepo
        self.signer = signer
        self.delegate = delegate
        self.dataSource = dataSource
    }
    
    func canHandle(request: Request) -> Bool {
        action.rawValue == request.method
    }
    
    func handle(request: Request) {
        fatalError("Subclass must implement")
    }
    
    func handleTransaction(from request: Request) -> (session: WalletConnectSession, tx: WalletConnectEthTransaction)? {
        do {
            let transaction = try request.parameter(of: WalletConnectEthTransaction.self, at: 0)
            
            guard let session = dataSource?.session(for: request, address: transaction.from) else {
                delegate?.sendReject(for: request, with: WalletConnectServiceError.sessionNotFound)
                return nil
            }
            
            return (session, transaction)
        } catch {
            delegate?.sendInvalid(request)
            return nil
        }
    }

    func sendReject(for request: Request, error: Error?) {
        delegate?.sendReject(for: request, with: error ?? WalletConnectServiceError.cancelled)
        bag = []
    }
    
    func buildTx(in session: WalletConnectSession, _ transaction: WalletConnectEthTransaction) -> AnyPublisher<(WalletModel, Transaction), Error> {
        let wallet = session.wallet
        
        guard let card = scannedCardsRepo.cards[wallet.cid] else {
            return .anyFail(error: WalletConnectServiceError.cardNotFound)
        }
        
        let blockchain = Blockchain.ethereum(testnet: wallet.isTestnet)
        let walletModels = assembly.makeWallets(from: CardInfo(card: card, artworkInfo: nil, twinCardInfo: nil), blockchains: [blockchain])
        
        guard
            let ethWalletModel = walletModels.first(where: { $0.wallet.address.lowercased() == transaction.from.lowercased() }),
            let gasLoader = ethWalletModel.walletManager as? EthereumGasLoader,
            let value = try? EthereumUtils.parseEthereumDecimal(transaction.value, decimalsCount: blockchain.decimalCount),
            let gas = transaction.gas?.hexToInteger ?? transaction.gasLimit?.hexToInteger
        else {
            return .anyFail(error: WalletConnectServiceError.failedToBuildTx)
        }
        
        let valueAmount = Amount(with: blockchain, address: wallet.address, type: .coin, value: value)
        ethWalletModel.update()
        
        // This zip attempting to load gas price and update wallet balance.
        // In some cases (ex. when swapping currencies on OpenSea) dApp didn't send gasPrice, that why we need to load this data from blockchain
        // Also we must identify that wallet failed to update balance.
        // If we couldn't get gasPrice and can't update wallet balance reject message will be send to dApp
        return Publishers.Zip(getGasPrice(for: valueAmount, tx: transaction, txSender: gasLoader, decimalCount: blockchain.decimalCount),
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
            .flatMap { (gasPrice, state) -> AnyPublisher<Transaction, Error> in
                Future { [weak self] promise in
                    let gasAmount = Amount(with: blockchain, address: wallet.address, type: .coin, value: Decimal(gas * gasPrice) / blockchain.decimalValue)
                    let totalAmount = valueAmount + gasAmount
                    let balance = ethWalletModel.wallet.amounts[.coin] ?? .zeroCoin(for: blockchain, address: transaction.from)
                    let dApp = session.session.dAppInfo
                    let message: String = {
                        
                        var m = ""
                        m += String(format: "wallet_connect_create_tx_message".localized,
                                    TapCardIdFormatter(cid: wallet.cid).formatted(),
                                    dApp.peerMeta.name,
                                    dApp.peerMeta.url.absoluteString,
                                    valueAmount.description,
                                    gasAmount.description,
                                    totalAmount.description,
                                    ethWalletModel.getBalance(for: .coin))
                        if (balance < totalAmount) {
                            m += "wallet_connect_create_tx_not_enough_funds".localized
                        }
                        return m
                    }()
                    let alert = WalletConnectUIBuilder.makeAlert(for: .sendTx, message: message, onAcceptAction: {
                        switch ethWalletModel.walletManager.createTransaction(amount: valueAmount, fee: gasAmount, destinationAddress: transaction.to, sourceAddress: transaction.from) {
                        case .success(var tx):
                            let contractDataString = transaction.data.drop0xPrefix
                            let wcTxData = Data(hexString: String(contractDataString))
                            tx.params = EthereumTransactionParams(data: wcTxData, gasLimit: gas, nonce: transaction.nonce?.hexToInteger)
                            promise(.success(tx))
                        case .failure(let error):
                            promise(.failure(error))
                        }
                    }, isAcceptEnabled: (balance >= totalAmount), onReject: {
                        promise(.failure(WalletConnectServiceError.cancelled))
                    })
                    self?.presentOnMain(vc: alert)
                }
                .eraseToAnyPublisher()
            }
            .map { (ethWalletModel, $0) }
            .eraseToAnyPublisher()
    }
    
    func presentOnMain(vc: UIViewController, delay: Double = 0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            UIApplication.modalFromTop(vc)
        }
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
    
}
