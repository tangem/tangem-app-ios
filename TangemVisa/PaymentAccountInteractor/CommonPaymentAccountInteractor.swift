//
//  CommonPaymentAccountInteractor.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct CommonPaymentAccountInteractor {
    let visaToken: Token

    private let customerCardInfo: VisaCustomerCardInfo
    private let isTestnet: Bool

    private let evmSmartContractInteractor: EVMSmartContractInteractor

    init(
        customerCardInfo: VisaCustomerCardInfo,
        visaToken: Token,
        isTestnet: Bool,
        evmSmartContractInteractor: EVMSmartContractInteractor
    ) {
        self.customerCardInfo = customerCardInfo
        self.visaToken = visaToken
        self.isTestnet = isTestnet
        self.evmSmartContractInteractor = evmSmartContractInteractor
    }
}

extension CommonPaymentAccountInteractor: VisaPaymentAccountInteractor {
    var accountAddress: String { customerCardInfo.paymentAccount }
    var cardWalletAddress: String { customerCardInfo.cardWalletAddress }

    func loadBalances() async throws -> VisaBalances {
        VisaLogger.info("Attempting to load all balances from balances")
        let loadedBalances: VisaBalances
        do {
            async let totalBalance = try await evmSmartContractInteractor.ethCall(
                request: VisaSmartContractRequest(
                    contractAddress: visaToken.contractAddress,
                    method: GetTotalBalanceMethod(paymentAccountAddress: accountAddress)
                )
            ).async()

            async let verifiedBalance = try requestAmount(type: .verifiedBalance)
            async let availableAmount = try requestAmount(type: .availableForPayment)
            async let blockedAmount = try requestAmount(type: .blocked)
            async let debtAmount = try requestAmount(type: .debt)

            loadedBalances = try await VisaBalances(
                totalBalance: convertToDecimal(totalBalance),
                verifiedBalance: convertToDecimal(verifiedBalance),
                available: convertToDecimal(availableAmount),
                blocked: convertToDecimal(blockedAmount),
                debt: convertToDecimal(debtAmount)
            )

            VisaLogger.info("All balances sucessfully loaded")
            return loadedBalances
        } catch {
            VisaLogger.error("Failed to load balances", error: error)
            throw error
        }
    }

    func loadCardSettings() async throws -> VisaPaymentAccountCardSettings {
        VisaLogger.info("Attempting to load card settings from payment account")
        do {
            try await checkWalletAddressAssociation()

            let cardSettings = try await loadCardSettingsFromBlockchain()
            VisaLogger.info("Card settings sucessfully loaded")
            return cardSettings
        } catch {
            VisaLogger.error("Failed to load card settings", error: error)
            throw error
        }
    }

    private func checkWalletAddressAssociation() async throws {
        let method = GetCardsListMethod()
        let paymentAccountAddressesResponse = try await evmSmartContractInteractor.ethCall(
            request: VisaSmartContractRequest(contractAddress: accountAddress, method: method)
        ).async()
        let addressesList = try AddressParser(isTestnet: isTestnet).parseAddressesResponse(paymentAccountAddressesResponse)

        guard addressesList.contains(cardWalletAddress) else {
            throw VisaPaymentAccountError.cardNotRegisteredToAccount
        }
    }

    private func loadCardSettingsFromBlockchain() async throws -> VisaPaymentAccountCardSettings {
        let method = GetCardInfoMethod(cardAddress: cardWalletAddress)
        let response = try await evmSmartContractInteractor.ethCall(
            request: VisaSmartContractRequest(contractAddress: accountAddress, method: method)
        ).async()

        let parser = PaymentAccountCardSettingsParser(decimalCount: visaToken.decimalCount)
        let settings = try parser.parse(response: response)
        return settings
    }
}

private extension CommonPaymentAccountInteractor {
    func requestAmount(type: GetAmountMethod.AmountType) async throws -> String {
        do {
            return try await evmSmartContractInteractor.ethCall(request: amountRequest(for: type)).async()
        } catch {
            VisaLogger.error("Failed to load amount of type: \(type.rawValue)", error: error)
            throw error
        }
    }

    func amountRequest(for amountType: GetAmountMethod.AmountType) -> VisaSmartContractRequest {
        let method = GetAmountMethod(amountType: amountType)
        return VisaSmartContractRequest(contractAddress: accountAddress, method: method)
    }

    func convertToDecimal(_ value: String) -> Decimal? {
        let decimal = EthereumUtils.parseEthereumDecimal(value, decimalsCount: visaToken.decimalCount)
        return decimal
    }
}

struct PaymentAccountCardSettingsParser {
    private let decimalCount: Int

    private let parsingItemsLength: [Int] = [3, 5, 15]
    private let parser = EthereumDataParser()
    private let limitsParser = LimitsResponseParser()

    init(decimalCount: Int) {
        self.decimalCount = decimalCount
    }

    func parse(response: String) throws -> VisaPaymentAccountCardSettings {
        let chunkedResponse = parser.split(string: response.removeHexPrefix())
        var chunks = splitArray(chunkedResponse, withLengths: parsingItemsLength)

        var supplementData = chunks.removeFirst()
        let initialized = parser.getBool(string: supplementData.removeFirst())
        let isOwner = parser.getBool(string: supplementData.removeFirst())
        let disabledDate = parser.getDateSince1970(string: supplementData.removeFirst())

        let otpParser = OTPSettingsParser()
        let otpSettings = try otpParser.parseOTP(responseChunks: chunks.removeFirst())

        let limitsParser = LimitsResponseParser()
        let limitsSettings = try limitsParser.parseResponse(chunks: chunks.removeFirst(), decimalCount: decimalCount)

        return .init(
            initialized: initialized,
            isOwner: isOwner,
            disableDate: disabledDate,
            otpState: otpSettings,
            limits: limitsSettings
        )
    }

    private func splitArray(_ array: [String], withLengths lengths: [Int]) -> [[String]] {
        var result: [[String]] = []
        var index = 0

        for length in lengths {
            let end = min(index + length, array.count)
            result.append(Array(array[index ..< end]))
            index += length
            if index >= array.count { break }
        }

        return result
    }
}

struct OTPSettingsParser {
    private let otpDataLength = 32
    private let numberOfOTPFields = 2
    private let parser = EthereumDataParser()

    func parseOTP(responseChunks: [String]) throws -> VisaOTPStateSettings {
        var chunks = responseChunks

        let changeDate = parser.getDateSince1970(string: chunks.removeLast())
        guard chunks.count == numberOfOTPFields * 2 else {
            throw VisaParserError.notEnoughOTPData
        }

        let oldOTPState = try parseSingleOTP(chunks: Array(chunks[0 ... 1]))
        let newOTPState = try parseSingleOTP(chunks: Array(chunks[2 ... 3]))
        return .init(
            oldValue: oldOTPState,
            newValue: newOTPState,
            changeDate: changeDate
        )
    }

    private func parseSingleOTP(chunks: [String]) throws -> VisaOTPState {
        guard chunks.count == numberOfOTPFields else {
            throw VisaParserError.notEnoughOTPData
        }

        let otpData = parser.getData(string: chunks[0])
        let counter = parser.getDecimal(string: chunks[1], decimalsCount: 0).intValue()

        return .init(
            otp: otpData,
            counter: counter
        )
    }
}

public struct VisaPaymentAccountCardSettings {
    public let initialized: Bool
    public let isOwner: Bool
    public let disableDate: Date
    public let otpState: VisaOTPStateSettings
    public let limits: VisaLimits
}

public struct VisaOTPStateSettings {
    public let oldValue: VisaOTPState
    public let newValue: VisaOTPState
    public let changeDate: Date
}

public struct VisaOTPState {
    public let otp: Data
    public let counter: Int
}

public enum VisaPaymentAccountError: String, LocalizedError {
    case cardNotRegisteredToAccount
    case cardIsNotActivated
}
