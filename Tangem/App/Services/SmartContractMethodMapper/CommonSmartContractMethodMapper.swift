//
//  CommonSmartContractMethodMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

class CommonSmartContractMethodMapper {
    private typealias JSON = [String: [String]]
    private lazy var json: JSON = {
        do {
            var json: JSON = [:]
            try DispatchQueue.global().sync {
                json = try JsonUtils.readBundleFile(with: "contract_methods", type: JSON.self)
            }
            return json
        } catch {
            AppLog.shared.debug("Contract methods doesn't found")
            return [:]
        }
    }()

    init() {}
}

// MARK: - SmartContractMethodMapper

extension CommonSmartContractMethodMapper: SmartContractMethodMapper {
    func getName(for method: String) -> String? {
        json.first(where: { $0.value.contains(method) })?.key
    }
}
