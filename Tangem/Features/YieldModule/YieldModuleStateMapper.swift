//
//  YieldModuleStateMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct YieldModuleStateMapper {
    let token: Token

    func map(
        walletModelData: WalletModelData,
        marketsInfo: [YieldModuleMarketInfo],
        pendingTransactions: [PendingTransactionRecord],
        yieldModuleStateRepository: YieldModuleStateRepository,
        yieldContract: String?
    ) -> YieldModuleManagerStateInfo {
        guard let marketInfo = marketsInfo.first(where: { $0.tokenContractAddress == token.contractAddress }) else {
            return YieldModuleManagerStateInfo(marketInfo: nil, state: .disabled)
        }

        if hasEnterTransactions(in: pendingTransactions, yieldContract: yieldContract) {
            return YieldModuleManagerStateInfo(marketInfo: marketInfo, state: .processing(action: .enter))
        }

        if hasExitTransactions(in: pendingTransactions, yieldContract: yieldContract) {
            return YieldModuleManagerStateInfo(marketInfo: marketInfo, state: .processing(action: .exit))
        }

        let state: YieldModuleManagerState

        switch walletModelData.state {
        case .created, .loading:
            state = .loading
        case .loaded:
            if let balance = walletModelData.balance,
               case .token(let token) = balance.type,
               let yieldSupply = token.metadata.yieldSupply {
                state = .active(
                    YieldSupplyInfo(
                        yieldContractAddress: yieldSupply.yieldContractAddress,
                        balance: balance,
                        isAllowancePermissionRequired: YieldAllowanceUtil().isPermissionRequired(
                            allowance: yieldSupply.allowance
                        ),
                        yieldModuleBalanceValue: yieldSupply.protocolBalanceValue
                    )
                )
            } else {
                state = marketInfo.isActive ? .notActive : .disabled
            }
        case .noAccount:
            state = .disabled
        case .failed(error: let error):
            let cachedState = yieldModuleStateRepository.state()
            if marketInfo.isActive || cachedState?.isEffectivelyActive == true {
                state = .failedToLoad(error: error, cachedState: cachedState)
            } else {
                state = .disabled
            }
        }

        return YieldModuleManagerStateInfo(marketInfo: marketInfo, state: state)
    }

    func hasEnterTransactions(in pendingTransactions: [PendingTransactionRecord], yieldContract: String?) -> Bool {
        let dummyDeployMethod = DeployYieldModuleMethod(
            walletAddress: String(),
            tokenContractAddress: String(),
            maxNetworkFee: .zero
        )
        let dummyInitMethod = InitYieldTokenMethod(tokenContractAddress: String(), maxNetworkFee: .zero)
        let dummyEnterMethod = EnterProtocolMethod(tokenContractAddress: String())
        let dummyReactivateMethod = ReactivateTokenMethod(tokenContractAddress: String(), maxNetworkFee: .zero)
        let dummyApproveMethod = ApproveERC20TokenMethod(spender: String(), amount: .zero)

        return hasTransactions(
            in: pendingTransactions,
            for: [
                dummyDeployMethod,
                dummyInitMethod,
                dummyReactivateMethod,
                dummyEnterMethod,
                dummyApproveMethod,
            ],
            yieldContract: yieldContract
        )
    }

    func hasExitTransactions(in pendingTransactions: [PendingTransactionRecord], yieldContract: String?) -> Bool {
        let dummyWithdrawAndDeactivateMethod = WithdrawAndDeactivateMethod(tokenContractAddress: String())
        return hasTransactions(
            in: pendingTransactions,
            for: [dummyWithdrawAndDeactivateMethod],
            yieldContract: yieldContract
        )
    }

    func hasTransactions(
        in pendingTransactions: [PendingTransactionRecord],
        for methods: [SmartContractMethod],
        yieldContract: String?
    ) -> Bool {
        return pendingTransactions.contains { record in
            guard let dataHex = record.ethereumTransactionDataHexString() else { return false }

            let methodMatch = methods.contains { method in
                dataHex.hasPrefix(method.methodId.removeHexPrefix().lowercased())
            }

            let tokenMatch = dataHex.contains(token.contractAddress.removeHexPrefix().lowercased())
            let yieldModuleMatch = yieldContract.flatMap { dataHex.contains($0.removeHexPrefix().lowercased()) } ?? false

            return methodMatch && (tokenMatch || yieldModuleMatch)
        }
    }
}

private extension PendingTransactionRecord {
    func ethereumTransactionDataHexString() -> String? {
        guard let params = transactionParams as? EthereumTransactionParams,
              let data = params.data else { return nil }

        return data.hexString.lowercased()
    }
}
