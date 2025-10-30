//
//  TangemMacroImplementationModule.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct TangemMacroImplementationModule: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AssociatedValueInsensitiveEquatableMarco.self,
    ]
}
