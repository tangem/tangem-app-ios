//
//  GnosisRegistrator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSdk
import Combine
import BigInt
import web3swift

class GnosisRegistrator {
    private let settings: GnosisRegistrator.Settings
    private let walletManager: WalletManager
    private var transactionProcessor: EthereumTransactionProcessor { walletManager as! EthereumTransactionProcessor }
    private var cardAddress: String { walletManager.wallet.address }

    init(settings: GnosisRegistrator.Settings, walletPublicKey: Data, factory: WalletManagerFactory) throws {
        self.settings = settings
        self.walletManager = try factory.makeWalletManager(blockchain: settings.blockchain, walletPublicKey: walletPublicKey)
    }

    func checkHasGas() -> AnyPublisher<Bool, Error> {
        walletManager.updatePublisher()
            .map { wallet -> Bool in
                if let coinAmount = wallet.amounts[.coin] {
                    return !coinAmount.isZero
                } else {
                    return false
                }
            }
            .eraseToAnyPublisher()
    }

    func getClaimableAmount() -> AnyPublisher<Amount, Error> {
        transactionProcessor.getAllowance(from: settings.treasurySafeAddress,
                                          to: cardAddress,
                                          contractAddress: settings.token.contractAddress)
            .tryMap { [settings] response -> Amount in
                let stringResponse = "\(response)".stripHexPrefix()

                guard let weiAmount = BigUInt(stringResponse),
                      let tokenAmount = Web3.Utils.formatToEthereumUnits(weiAmount,
                                                                         toUnits: .eth,
                                                                         decimals: settings.token.decimalCount,
                                                                         decimalSeparator: ".",
                                                                         fallbackToScientific: false),
                      let decimalAmount = Decimal(string: tokenAmount) else {
                    throw SaltPayRegistratorError.failedToParseAllowance
                }

                return Amount(with: settings.token, value: decimalAmount)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func sendTransactions(_ transactions: [SignedEthereumTransaction]) -> AnyPublisher<Void, Error> {
        let sortedByNonce = transactions.sorted { $0.transaction.nonce < $1.transaction.nonce }
        let publishers = sortedByNonce.map { transactionProcessor.send($0) }

        let start = Just("").setFailureType(to: Error.self).eraseToAnyPublisher()
        let pipe = publishers.reduce(start) { partialResult, nextPublisher in
            partialResult.flatMap { _ in nextPublisher }.eraseToAnyPublisher()
        }

        return pipe
            .map { _ in return () }
            .eraseToAnyPublisher()
    }

    func makeSetSpendLimitTx(value: Decimal) -> AnyPublisher<CompiledEthereumTransaction, Error>  {
        do {
            let limitAmount = Amount(with: settings.token, value: value)
            let setSpedLimitData = try makeTxData(sig: Signatures.setSpendLimit, address: cardAddress, amount: limitAmount)

            return transactionProcessor.getFee(to: settings.otpProcessorContractAddress, data: "0x\(setSpedLimitData.hexString)", amount: nil)
                //  .replaceError(with: [Amount(with: settings.blockchain, value: 0.00001), Amount(with: settings.blockchain, value: 0.00001)]) //[REDACTED_TODO_COMMENT]
                .tryMap { fees -> Transaction in
                    let params = EthereumTransactionParams(data: setSpedLimitData, nonce: self.transactionProcessor.initialNonce)
                    var transaction = try self.walletManager.createTransaction(amount: Amount.zeroCoin(for: self.settings.blockchain),
                                                                               fee: fees[1],
                                                                               destinationAddress: self.settings.otpProcessorContractAddress)
                    transaction.params = params

                    return transaction
                }
                .flatMap { [transactionProcessor] tx in
                    transactionProcessor.buildForSign(tx)
                }
                .eraseToAnyPublisher()
        } catch {
            return .anyFail(error: error)
        }
    }

    func makeInitOtpTx(rootOTP: Data, rootOTPCounter: Int) -> AnyPublisher<CompiledEthereumTransaction, Error>  {
        let initOTPData = Signatures.initOTP + rootOTP.prefix(16) + Data(count: 46) + rootOTPCounter.bytes2

        return transactionProcessor.getFee(to: settings.otpProcessorContractAddress, data: "0x\(initOTPData.hexString)", amount: nil)
            // .replaceError(with: [Amount(with: settings.blockchain, value: 0.00001), Amount(with: settings.blockchain, value: 0.00001)]) //[REDACTED_TODO_COMMENT]
            .tryMap { fees -> Transaction in
                let params = EthereumTransactionParams(data: initOTPData, nonce: self.transactionProcessor.initialNonce + 1)
                var transaction = try self.walletManager.createTransaction(amount: Amount.zeroCoin(for: self.settings.blockchain),
                                                                           fee: fees[1],
                                                                           destinationAddress: self.settings.otpProcessorContractAddress)
                transaction.params = params

                return transaction
            }
            .flatMap { [transactionProcessor] tx in
                transactionProcessor.buildForSign(tx)
            }
            .eraseToAnyPublisher()
    }

    func makeSetWalletTx() -> AnyPublisher<CompiledEthereumTransaction, Error>  {
        do {
            let setWalletData = try makeTxData(sig: Signatures.setWallet, address: cardAddress, amount: nil)

            return transactionProcessor.getFee(to: settings.otpProcessorContractAddress, data: "0x\(setWalletData.hexString)", amount: nil)
                //   .replaceError(with: [Amount(with: settings.blockchain, value: 0.00001), Amount(with: settings.blockchain, value: 0.00001)]) //[REDACTED_TODO_COMMENT]
                .tryMap { fees -> Transaction in
                    let params = EthereumTransactionParams(data: setWalletData, nonce: self.transactionProcessor.initialNonce + 2)
                    var transaction = try self.walletManager.createTransaction(amount: Amount.zeroCoin(for: self.settings.blockchain),
                                                                               fee: fees[1],
                                                                               destinationAddress: self.settings.otpProcessorContractAddress)
                    transaction.params = params

                    return transaction
                }
                .flatMap { [transactionProcessor] tx in
                    transactionProcessor.buildForSign(tx)
                }
                .eraseToAnyPublisher()
        } catch {
            return .anyFail(error: error)
        }
    }

    func makeApprovalTx(value: Decimal) -> AnyPublisher<CompiledEthereumTransaction, Error>  {
        let approveAmount = Amount(with: settings.token, value: value)
        let zeroApproveAmount = Amount(with: approveAmount, value: 0)

        do {
            let approveData = try makeTxData(sig: Signatures.approve, address: settings.otpProcessorContractAddress, amount: approveAmount)

            return transactionProcessor.getFee(to: settings.token.contractAddress, data: "0x\(approveData.hexString)", amount: nil)
                //   .replaceError(with: [Amount(with: settings.blockchain, value: 0.00001), Amount(with: settings.blockchain, value: 0.00001)]) //[REDACTED_TODO_COMMENT]
                .tryMap { fees -> Transaction in
                    let params = EthereumTransactionParams(data: approveData, nonce: self.transactionProcessor.initialNonce + 3)
                    var transaction = try self.walletManager.createTransaction(amount: zeroApproveAmount,
                                                                               fee: fees[1],
                                                                               destinationAddress: "")
                    transaction.params = params

                    return transaction
                }
                .flatMap { [transactionProcessor] tx in
                    transactionProcessor.buildForSign(tx)
                }
                .eraseToAnyPublisher()
        } catch {
            return .anyFail(error: error)
        }
    }

    func makeClaimTx(value: Amount) -> AnyPublisher<CompiledEthereumTransaction, Error>  {
        let zeroApproveAmount = Amount(with: value, value: 0)
        do {
            let approveData = try makeTxData(sig: Signatures.claim, address: settings.treasurySafeAddress, address2: cardAddress, amount: value)

            return transactionProcessor.getFee(to: settings.token.contractAddress, data: "0x\(approveData.hexString)", amount: nil)
                //   .replaceError(with: [Amount(with: settings.blockchain, value: 0.00001), Amount(with: settings.blockchain, value: 0.00001)]) //[REDACTED_TODO_COMMENT]
                .tryMap { fees -> Transaction in
                    let params = EthereumTransactionParams(data: approveData, nonce: self.transactionProcessor.initialNonce)
                    var transaction = try self.walletManager.createTransaction(amount: zeroApproveAmount,
                                                                               fee: fees[1],
                                                                               destinationAddress: "")
                    transaction.params = params

                    return transaction
                }
                .flatMap { [transactionProcessor] tx in
                    transactionProcessor.buildForSign(tx)
                }
                .eraseToAnyPublisher()
        } catch {
            return .anyFail(error: error)
        }
    }

    private func makeTxData(sig: Data, address: String, address2: String? = nil, amount: Amount?) throws -> Data {
        let addressData = Data(hexString: address).aligned()

        var data: Data = sig + addressData

        if let address2 {
            let address2Data = Data(hexString: address2).aligned()
            data += address2Data
        }

        if let amount {
            guard let amountData = amount.encodedAligned else {
                throw SaltPayRegistratorError.failedToMakeTxData
            }

            data += amountData
        }

        return data
    }
}

extension GnosisRegistrator {
    enum Signatures {
        static let approve: Data = "approve(address,uint256)".signedPrefix
        static let setSpendLimit: Data = "setSpendLimit(address,uint256)".signedPrefix
        static let initOTP: Data = "initOTP(bytes16,uint16)".signedPrefix // 0x0ac81ec3
        static let setWallet: Data = "setWallet(address)".signedPrefix // 0xdeaa59df
        static let claim: Data = "transferFrom(address,address,uint256)".signedPrefix // 0xdeaa59df
    }
}

extension GnosisRegistrator {
    enum Settings {
        case main

        var token: Token {
            .init(sdkToken, id: "wrapped-xdai")
        }

        var otpProcessorContractAddress: String {
            switch self {
            case .main:
                return "0xc659f4FEd7A84a188F54cBA4A7a49D77c1a20522"
            }
        }

        var blockchain: Blockchain {
            switch self {
            case .main:
                return .saltPay
            }
        }

        var treasurySafeAddress: String {
            "0x24A3c2382497075b6D93258f5938f7B661c06318"
        }

        private var sdkToken: WalletData.Token {
            switch self {
            case .main:
                return .init(name: "WXDAI",
                             symbol: "WXDAI",
                             contractAddress: "0x4200000000000000000000000000000000000006",
                             decimals: 18)
            }
        }
    }
}

fileprivate extension String {
    var signedPrefix: Data {
        self.data(using: .utf8)!.sha3(.keccak256).prefix(4)
    }
}
