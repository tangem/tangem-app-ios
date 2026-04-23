//
//  MacroError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftDiagnostics

enum MacroError: DiagnosticMessage {
    case requiresArgument(macro: String)
    case applicableOnlyToEnum(macro: String)

    var message: String {
        switch self {
        case .requiresArgument(let macro):
            return "`\(macro)` requires at least one argument"
        case .applicableOnlyToEnum(let macro):
            return "`\(macro)` can only be applied to enum declarations"
        }
    }

    var diagnosticID: MessageID {
        switch self {
        case .requiresArgument(let macro),
             .applicableOnlyToEnum(let macro):
            MessageID(domain: macro, id: "Error")
        }
    }

    var severity: DiagnosticSeverity { .error }
}
