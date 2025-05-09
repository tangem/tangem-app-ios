//
//  DataCollectors.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk
import TangemStaking
import TangemVisa

protocol EmailDataCollector: LogFileProvider {}

extension EmailDataCollector {
    var fileName: String {
        LogFilesNames.infoLogs
    }

    func prepareLogFile() -> URL {
        let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
        try? logData?.write(to: url)
        return url
    }
}

private extension EmailDataCollector {
    func formatData(_ collectedInfo: [EmailCollectedData], appendDeviceInfo: Bool = true) -> Data? {
        let sessionPrefix = "Session ID: \(AppConstants.sessionId)\n"
        let collectedString = collectedInfo.reduce("") { $0 + $1.type.title + $1.data + "\n" } + (appendDeviceInfo ? DeviceInfoProvider.info() : "")
        let messageToConvert = "\(sessionPrefix)\n\(collectedString)"
        return messageToConvert.data(using: .utf8)
    }
}

// MARK: - BaseDataCollector

struct BaseDataCollector: EmailDataCollector {
    var logData: Data? {
        ("----------\n" + DeviceInfoProvider.info()).data(using: .utf8)
    }
}

// MARK: - NegativeFeedbackDataCollector

struct NegativeFeedbackDataCollector: EmailDataCollector {
    var logData: Data? {
        formatData(userWalletEmailData)
    }

    private let userWalletEmailData: [EmailCollectedData]

    init(userWalletEmailData: [EmailCollectedData]) {
        self.userWalletEmailData = userWalletEmailData
    }
}

// MARK: - SendScreenDataCollector

struct SendScreenDataCollector: EmailDataCollector {
    var logData: Data? {
        var data = userWalletEmailData
        data.append(.separator(.dashes))

        data.append(EmailCollectedData(
            type: .card(.blockchain),
            data: walletModel.tokenItem.blockchainNetwork.blockchain.displayName
        ))

        switch amount.type {
        case .token(let token):
            data.append(EmailCollectedData(type: .card(.token), data: token.symbol))
            data.append(EmailCollectedData(type: .token(.decimals), data: "\(token.decimalCount)"))
            data.append(EmailCollectedData(type: .token(.contractAddress), data: token.contractAddress))
        case .coin, .reserve, .feeResource:
            break
        }

        // Did display current wallet manager curreny host by provider
        data.append(EmailCollectedData(type: .wallet(.walletManagerHost), data: walletModel.blockchainDataProvider.currentHost))

        if let outputsDescription = walletModel.blockchainDataProvider.outputsCount?.description {
            data.append(EmailCollectedData(type: .wallet(.outputsCount), data: outputsDescription))
        }

        if let errorDescription = lastError?.error.detailedLocalizedDescription {
            data.append(EmailCollectedData(type: .error, data: errorDescription))
        }

        let derivationPath = walletModel.publicKey.derivationPath
        data.append(EmailCollectedData(type: .wallet(.derivationPath), data: derivationPath?.rawPath ?? "[default]"))

        data.append(.separator(.dashes))

        data.append(contentsOf: [
            EmailCollectedData(type: .send(.sourceAddress), data: walletModel.defaultAddressString),
            EmailCollectedData(type: .send(.destinationAddress), data: destination),
            EmailCollectedData(type: .send(.amount), data: amount.description),
            EmailCollectedData(type: .send(.fee), data: fee.description),
            EmailCollectedData(type: .send(.isFeeIncluded), data: "\(isFeeIncluded)"),
        ])

        if let stakingAction {
            data.append(EmailCollectedData(type: .staking(.stakingAction), data: stakingAction.title))
        }

        if let validator {
            data.append(contentsOf: [
                EmailCollectedData(type: .staking(.validatorName), data: validator.name),
                EmailCollectedData(type: .staking(.validatorAddress), data: validator.address),
            ])
        }

        // The last retry attempt by the host caused an error with txHex string
        if let exceptionHost = lastError?.lastRetryHost, let txHex = lastError?.tx {
            data.append(EmailCollectedData(type: .wallet(.exceptionWalletManagerHost), data: exceptionHost))
            data.append(EmailCollectedData(type: .send(.transactionHex), data: txHex))
        }

        return formatData(data)
    }

    private let userWalletEmailData: [EmailCollectedData]
    private let walletModel: any WalletModel
    private let fee: Amount
    private let destination: String
    private let amount: Amount
    private let isFeeIncluded: Bool
    private let lastError: SendTxError?
    private let stakingAction: StakingAction.ActionType?
    private let validator: ValidatorInfo?

    init(
        userWalletEmailData: [EmailCollectedData],
        walletModel: any WalletModel,
        fee: Amount,
        destination: String,
        amount: Amount,
        isFeeIncluded: Bool,
        lastError: SendTxError?,
        stakingAction: StakingAction.ActionType?,
        validator: ValidatorInfo?
    ) {
        self.userWalletEmailData = userWalletEmailData
        self.walletModel = walletModel
        self.fee = fee
        self.destination = destination
        self.amount = amount
        self.isFeeIncluded = isFeeIncluded
        self.lastError = lastError
        self.stakingAction = stakingAction
        self.validator = validator
    }
}

// MARK: - PushScreenDataCollector

struct PushScreenDataCollector: EmailDataCollector {
    var logData: Data? {
        var data = userWalletEmailData
        data.append(.separator(.dashes))
        switch amount.type {
        case .coin:
            data.append(EmailCollectedData(type: .card(.blockchain), data: amount.currencySymbol))
        case .token(let token):
            data.append(EmailCollectedData(type: .card(.token), data: token.symbol))
        default:
            break
        }

        data.append(contentsOf: [
            EmailCollectedData(type: .wallet(.walletManagerHost), data: walletModel.blockchainDataProvider.currentHost),
            EmailCollectedData(type: .error, data: lastError?.detailedLocalizedDescription ?? "Unknown error"),
            .separator(.dashes),
            EmailCollectedData(type: .send(.pushingTxHash), data: pushingTxHash),
            EmailCollectedData(type: .send(.pushingFee), data: pushingFee?.description ?? "[unknown]"),
            EmailCollectedData(type: .send(.sourceAddress), data: source),
            EmailCollectedData(type: .send(.destinationAddress), data: destination),
            EmailCollectedData(type: .send(.amount), data: amount.description),
            EmailCollectedData(type: .send(.fee), data: fee?.description ?? "[unknown]"),
        ])

        return formatData(data)
    }

    private let userWalletEmailData: [EmailCollectedData]
    private let walletModel: any WalletModel
    private let fee: Amount?
    private let pushingFee: Amount?
    private let destination: String
    private let source: String
    private let amount: Amount
    private let pushingTxHash: String
    private let lastError: Error?

    init(userWalletEmailData: [EmailCollectedData], walletModel: any WalletModel, fee: Amount?, pushingFee: Amount?, destination: String, source: String, amount: Amount, pushingTxHash: String, lastError: Error?) {
        self.userWalletEmailData = userWalletEmailData
        self.walletModel = walletModel
        self.fee = fee
        self.pushingFee = pushingFee
        self.destination = destination
        self.source = source
        self.amount = amount
        self.pushingTxHash = pushingTxHash
        self.lastError = lastError
    }
}

// MARK: - DetailsFeedbackDataCollector

struct DetailsFeedbackDataCollector: EmailDataCollector {
    var logData: Data? {
        var dataToFormat: [EmailCollectedData] = []

        for dataItem in data {
            dataToFormat.append(contentsOf: dataItem.userWalletEmailData)

            for walletModel in dataItem.walletModels {
                dataToFormat.append(.separator(.dashes))
                dataToFormat.append(EmailCollectedData(type: .card(.blockchain), data: walletModel.tokenItem.blockchain.displayName))

                let derivationPath = walletModel.publicKey.derivationPath
                dataToFormat.append(EmailCollectedData(type: .wallet(.derivationPath), data: derivationPath?.rawPath ?? "[default]"))

                if let outputsDescription = walletModel.blockchainDataProvider.outputsCount?.description {
                    dataToFormat.append(EmailCollectedData(type: .wallet(.outputsCount), data: outputsDescription))
                }

                if let token = walletModel.tokenItem.amountType.token {
                    dataToFormat.append(EmailCollectedData(type: .token(.id), data: token.id ?? "[custom token]"))
                    dataToFormat.append(EmailCollectedData(type: .token(.decimals), data: "\(token.decimalCount)"))
                    dataToFormat.append(EmailCollectedData(type: .token(.name), data: token.name))
                    dataToFormat.append(EmailCollectedData(type: .token(.contractAddress), data: token.contractAddress))
                }

                dataToFormat.append(EmailCollectedData(type: .wallet(.walletManagerHost), data: walletModel.blockchainDataProvider.currentHost))
                if walletModel.addressNames.count > 1 {
                    var explorerLinks = "Multiple explorers links: "
                    var addresses = "Multiple addresses: "
                    let suffix = " ; \n"
                    walletModel.addressNames.enumerated().forEach {
                        let namePrefix = $0.element + " - "
                        addresses += namePrefix + walletModel.displayAddress(for: $0.offset) + suffix
                        explorerLinks += namePrefix + (walletModel.exploreURL(for: $0.offset)?.absoluteString ?? "") + suffix
                    }
                    explorerLinks.removeLast(suffix.count)
                    addresses.removeLast(suffix.count)

                    dataToFormat.append(EmailCollectedData(type: .wallet(.walletAddress), data: addresses))
                    dataToFormat.append(EmailCollectedData(type: .wallet(.explorerLink), data: explorerLinks))
                } else if walletModel.addressNames.count == 1 {
                    dataToFormat.append(EmailCollectedData(type: .wallet(.walletAddress), data: walletModel.displayAddress(for: 0)))
                    dataToFormat.append(EmailCollectedData(type: .wallet(.explorerLink), data: walletModel.exploreURL(for: 0)?.absoluteString ?? ""))
                }
            }

            dataToFormat.append(.separator(.dashes))
            dataToFormat.append(.separator(.dashes))
        }

        return formatData(dataToFormat)
    }

    private let data: [DetailsFeedbackData]

    init(data: [DetailsFeedbackData]) {
        self.data = data
    }
}

// MARK: - DetailsFeedbackData

struct DetailsFeedbackData {
    let userWalletEmailData: [EmailCollectedData]
    let walletModels: [any WalletModel]
}

// MARK: - TokenErrorDescriptionDataCollector

struct TokenErrorDescriptionDataCollector: EmailDataCollector {
    var logData: Data? {
        var dataToFormat: [EmailCollectedData] = []
        dataToFormat.append(.separator(.dashes))

        dataToFormat.append(EmailCollectedData(type: .token(.id), data: tokenId))
        dataToFormat.append(EmailCollectedData(type: .token(.name), data: tokenName))

        dataToFormat.append(.separator(.dashes))
        return formatData(dataToFormat)
    }

    private let tokenId: String
    private let tokenName: String

    init(tokenId: String, tokenName: String) {
        self.tokenId = tokenId
        self.tokenName = tokenName
    }
}

// MARK: - Visa

struct VisaDisputeTransactionDataCollector: EmailDataCollector {
    var logData: Data? {
        var dataToFormat = [EmailCollectedData]()

        dataToFormat.append(.init(type: .visaDisputeTransaction(.id), data: transaction.id.description))
        dataToFormat.append(.init(type: .visaDisputeTransaction(.type), data: transaction.type))
        dataToFormat.append(.init(type: .visaDisputeTransaction(.status), data: transaction.status))
        dataToFormat.append(.init(type: .visaDisputeTransaction(.blockchainAmount), data: transaction.blockchainAmount.description))
        dataToFormat.append(.init(type: .visaDisputeTransaction(.blockchainCoinName), data: transaction.blockchainCoinName))
        dataToFormat.append(.init(type: .visaDisputeTransaction(.transactionAmount), data: transaction.transactionAmount.description))
        dataToFormat.append(.init(type: .visaDisputeTransaction(.currencyCode), data: transaction.transactionCurrencyCode.description))
        dataToFormat.append(.init(type: .visaDisputeTransaction(.billingAmount), data: transaction.billingAmount.description))
        dataToFormat.append(.init(type: .visaDisputeTransaction(.billingCurrencyCode), data: transaction.billingCurrencyCode.description))
        dataToFormat.append(.init(type: .visaDisputeTransaction(.merchantName), data: transaction.merchantName ?? ""))
        dataToFormat.append(.init(type: .visaDisputeTransaction(.merchantCity), data: transaction.merchantCity ?? ""))
        dataToFormat.append(.init(type: .visaDisputeTransaction(.merchantCountryCode), data: transaction.merchantCountryCode ?? ""))
        dataToFormat.append(.init(type: .visaDisputeTransaction(.merchantCategoryCode), data: transaction.merchantCategoryCode ?? ""))

        dataToFormat.append(.separator(.dashes))
        dataToFormat.append(.init(type: .visaDisputeTransaction(.requests), data: ""))

        let dateFormatter = ISO8601DateFormatter()
        for request in transaction.requests {
            dataToFormat.append(.separator(.dashes))
            dataToFormat.append(.init(type: .visaDisputeTransaction(.id), data: request.id.description))
            dataToFormat.append(.init(type: .visaDisputeTransaction(.type), data: request.type))
            dataToFormat.append(.init(type: .visaDisputeTransaction(.status), data: request.status))
            dataToFormat.append(.init(type: .visaDisputeTransaction(.blockchainAmount), data: request.blockchainAmount.description))
            dataToFormat.append(.init(type: .visaDisputeTransaction(.transactionAmount), data: request.transactionAmount.description))
            dataToFormat.append(.init(type: .visaDisputeTransaction(.currencyCode), data: request.transactionCurrencyCode.description))
            dataToFormat.append(.init(type: .visaDisputeTransaction(.billingAmount), data: request.billingAmount.description))
            dataToFormat.append(.init(type: .visaDisputeTransaction(.billingCurrencyCode), data: request.billingCurrencyCode.description))
            dataToFormat.append(.init(type: .visaDisputeTransaction(.errorCode), data: request.errorCode.description))
            dataToFormat.append(.init(type: .visaDisputeTransaction(.date), data: dateFormatter.string(from: request.date)))
            dataToFormat.append(.init(type: .visaDisputeTransaction(.transactionHash), data: request.transactionHash ?? ""))
            dataToFormat.append(.init(type: .visaDisputeTransaction(.transactionStatus), data: request.transactionStatus ?? ""))
        }

        return formatData(dataToFormat)
    }

    private let transaction: VisaTransactionRecord

    init(transaction: VisaTransactionRecord) {
        self.transaction = transaction
    }
}
