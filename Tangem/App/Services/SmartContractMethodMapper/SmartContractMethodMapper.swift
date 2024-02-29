//
//  SmartContractMethodMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol SmartContractMethodMapper {
    func getName(for method: String) -> String?
}

private struct SmartContractMethodMapperKey: InjectionKey {
    static var currentValue: SmartContractMethodMapper = CommonSmartContractMethodMapper()
}

extension InjectedValues {
    var smartContractMethodMapper: SmartContractMethodMapper {
        get { Self[SmartContractMethodMapperKey.self] }
        set { Self[SmartContractMethodMapperKey.self] = newValue }
    }
}
