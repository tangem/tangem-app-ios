//
//  SolanaEd25519Tests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
@testable import BlockchainSdk
@testable import SolanaSwift
import Testing

struct SolanaEd25519Tests {
    private let manager: SolanaWalletManager

    private let walletPubKey = Data(hex: "B148CC30B144E8F214AE5754C753C40A9BF2A3359DB4246E03C6A2F61A82C282")
    private let address = "Cw3YcfqzRSa7xT7ecpR5E4FKDQU6aaxz5cWje366CZbf"
    private let blockchain = Blockchain.solana(curve: .ed25519, testnet: false)
    private let feeParameters = SolanaFeeParameters(computeUnitLimit: nil, computeUnitPrice: nil, accountCreationFee: 0)
    private let coinSigner = SolanaSignerTestUtility.CoinSigner()

    init() {
        let networkingRouter = SolanaDummyNetworkRouter(
            endpoints: [.devnetSolana],
            apiLogger: nil
        )

        let solanaSdk = Solana(router: networkingRouter, accountStorage: SolanaDummyAccountStorage())
        let service = AddressServiceFactory(blockchain: blockchain).makeAddressService()

        let address = try! service.makeAddress(from: walletPubKey)
        let wallet = Wallet(blockchain: blockchain, addresses: [.default: address])

        manager = .init(wallet: wallet)
        manager.solanaSdk = solanaSdk
        manager.usePriorityFees = false
        manager.networkService = SolanaNetworkService(
            solanaSdk: solanaSdk,
            blockchain: blockchain,
            hostProvider: networkingRouter
        )
    }

    @Test
    func coinTransactionSize() async throws {
        let transaction = Transaction(
            amount: .zeroCoin(for: blockchain),
            fee: Fee(.zeroCoin(for: blockchain), parameters: feeParameters),
            sourceAddress: manager.wallet.address,
            destinationAddress: "BmAzxn8WLYU3gEw79ATUdSUkMT53MeS5LjapBQB8gTPJ",
            changeAddress: manager.wallet.address,
            contractAddress: nil
        )

        do {
            _ = try await manager.send(transaction, signer: coinSigner).async()
        } catch let sendTxError as SendTxError {
            guard let castedError = sendTxError.error as? SolanaError else {
                throw Error.invalid
            }

            #expect(castedError.errorDescription == SolanaError.nullValue.errorDescription)
        } catch {
            throw error
        }
    }

    func testTokenTransactionSize() async throws {
        let type: Amount.AmountType = .token(
            value: .init(
                name: "My Token",
                symbol: "MTK",
                contractAddress: "BHZxQcNpty7W8EVT2kxWREZ9QxNDigXrjRb7SWTAt9YK",
                decimalCount: 9
            )
        )
        let transaction = Transaction(
            amount: Amount(with: blockchain, type: type, value: 0),
            fee: Fee(Amount(with: blockchain, type: type, value: 0), parameters: feeParameters),
            sourceAddress: manager.wallet.address,
            destinationAddress: "BmAzxn8WLYU3gEw79ATUdSUkMT53MeS5LjapBQB8gTPJ",
            changeAddress: manager.wallet.address
        )

        do {
            _ = try await manager.send(transaction, signer: coinSigner).async()
        } catch let sendTxError as SendTxError {
            guard let castedError = sendTxError.error as? SolanaError else {
                throw Error.invalid
            }

            #expect(castedError.errorDescription == SolanaError.nullValue.errorDescription)
        } catch {
            throw error
        }
    }
}

extension SolanaEd25519Tests {
    enum Error: LocalizedError {
        case invalid

        var errorDescription: String? {
            return "Wrong error returned from manager"
        }
    }
}
