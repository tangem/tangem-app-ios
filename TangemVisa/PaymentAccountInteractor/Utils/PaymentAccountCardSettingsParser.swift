//
//  PaymentAccountCardSettingsParser.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

/// Parses blockchain response data into structured card settings including OTP and limits.
struct PaymentAccountCardSettingsParser {
    private let decimalCount: Int

    private let parsingItemsLength: [Int] = [3, 5, 15]
    private let parser = EthereumDataParser()
    private let limitsParser = LimitsResponseParser()

    init(decimalCount: Int) {
        self.decimalCount = decimalCount
    }

    /// Parses the smart contract response to extract card settings.
    /// - Parameter response: A hex-encoded blockchain response string.
    /// - Returns: Parsed `VisaPaymentAccountCardSettings`.
    /// - Throws: An error if the parsing fails.
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

/// Parses OTP (One-Time Password) state settings from blockchain responses.
struct OTPSettingsParser {
    private let numberOfOTPFields = 2
    private let parser = EthereumDataParser()

    /// Parses old and new OTP states from the response chunks.
    /// - Parameter responseChunks: An array of strings representing raw response chunks.
    /// - Returns: A `VisaOTPStateSettings` instance containing OTP states and change date.
    /// - Throws: An error if data is insufficient or invalid.
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

    /// Parses a single OTP state from the response chunks.
    /// - Parameter chunks: An array of two elements: OTP data and counter.
    /// - Returns: A `VisaOTPState` with decoded values.
    /// - Throws: An error if the chunk count is invalid.
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
