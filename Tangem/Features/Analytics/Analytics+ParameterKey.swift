//
//  Analytics+ParameterKey.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension Analytics {
    enum ParameterKey: String {
        case blockchain
        case firmware = "Firmware"
        case action = "Action"
        case errorDescription = "Error Description"
        case errorCode = "Error Code"
        case errorMessage = "Error Message"
        case errorType = "Error Type"
        case newSecOption = "new_security_option"
        case errorKey = "Tangem SDK error key"
        case source = "Source"
        case period = "Period"
        case type
        case currency = "Currency Type" // fiat
        case success
        case token = "Token"
        case tokens = "Tokens"
        case tokensCount = "Tokens Count"
        case tokenFound = "Token Found"
        case derivationPath = "Derivation Path"
        case derivation = "Derivation"
        case network = "Network"
        case networkId = "Network Id"
        case contractAddress = "Contract Address"
        case mode = "Mode"
        case state = "State"
        case basicCurrency = "Currency"
        case batch = "Batch"
        case cardsCount = "Cards Count"
        case walletCount = "Wallet Count"
        case sku = "SKU"
        case amount = "Amount"
        case count = "Count"
        case couponCode = "Coupon Code"
        case productType = "Product Type"
        case sendToken = "Send Token"
        case receiveToken = "Receive Token"
        case commonType = "Type"
        case signInType = "Sign in type"
        case balance = "Balance"
        case creationType = "Creation Type"
        case seedLength = "Seed Phrase Length"
        case status = "Status"
        case option
        case feeType = "Fee Type"
        case ensAddress = "ENS Address"
        case nonce = "Nonce"
        case permissionType = "Permission Type"
        case validation = "Validation"
        case memo = "Memo"
        case walletsCount = "Wallets Count"
        case walletHasBackup = "Backuped"
        case exceptionHost = "exception_host"
        case selectedHost = "selected_host"
        case region
        case clientType = "Client Type"
        case programName = "Program Name"
        case networks = "Networks"
        case methodName = "Method Name"
        case groupType = "Group"
        case sortType = "Sort"
        case tokenChosen = "Token Chosen"
        case availableTokens = "Available tokens"
        case provider = "Provider"
        case commission = "Commission"
        case place = "Place"
        case result = "Result"
        case input = "Input"
        case passphrase = "Passphrase"
        case button = "Button"
        case link = "Link"

        case fromSummary = "From Summary"
        case valid = "Valid"

        case userWalletId = "User Wallet ID"

        case sendBlockchain = "Send Blockchain"
        case receiveBlockchain = "Receive Blockchain"

        case ens = "ENS"

        case validatorsCount = "Validators Count"
        case validator = "Validator"

        case walletForm = "WalletForm"
        case reason = "Reason"
        case residence = "Residence"
        case paymentMethod = "Payment Method"

        case watched = "Watched"

        // MARK: - Wallet Connect

        case walletConnectDAppName = "DApp Name"
        case walletConnectDAppUrl = "DApp Url"
        case walletConnectBlockchain = "Blockchain"
        case walletConnectDAppDomainVerification = "Domain Verification"
        case walletConnectTransactionEmulationStatus = "Emulation Status"

        // MARK: - NFT

        case nftCollectionsCount = "Collections"
        case nftAssetsCount = "Nft"
        case nftStandard = "Standard"
        case nftDummyCollectionsCount = "No collection"
    }
}
