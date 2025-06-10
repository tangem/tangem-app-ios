//
//  CommonSmartContractMethodMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

class CommonSmartContractMethodMapper {
    private typealias DataSource = [String: ContractMethod]

    private lazy var dataSource: DataSource = {
        do {
            return try DispatchQueue.global().sync {
                return try JsonUtils.readBundleFile(with: "contract_methods", type: DataSource.self)
            }
        } catch {
            AppLogger.error("Can't map EVM contract methods data source", error: error)
            return [:]
        }
    }()
}

// MARK: - SmartContractMethodMapper

extension CommonSmartContractMethodMapper: SmartContractMethodMapper {
    func getName(for method: String) -> String? {
        dataSource[method]?.name
    }
}

private extension CommonSmartContractMethodMapper {
    struct ContractMethod: Decodable {
        let name: String
        let source: URL?
        let info: String?
    }
}
