//
//  RawCaseNameMacro.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftSyntaxMacros
import SwiftSyntax
import SwiftDiagnostics

public struct RawCaseNameMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // Ensure the macro is applied only to enums
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            let diagnostic = Diagnostic(
                node: Syntax(declaration),
                message: MacroError.applicableOnlyToEnum(macro: "RawCaseNameMacro")
            )
            context.diagnose(diagnostic)
            return []
        }

        // Build switch cases mapping each case to its identifier string, ignoring associated values
        let caseLinesArrays: [[String]] = enumDecl.memberBlock.members.map { member -> [String] in
            guard let enumCaseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { return [] }

            return enumCaseDecl.elements.map { element -> String in
                let caseName = element.name.text
                if let assoc = element.parameterClause {
                    let count = assoc.parameters.count
                    if count == 0 {
                        return "case .\(caseName): return \"\(caseName)\""
                    } else {
                        let wildcards = Array(repeating: "_", count: count).joined(separator: ", ")
                        return "case .\(caseName)(\(wildcards)): return \"\(caseName)\""
                    }
                } else {
                    return "case .\(caseName): return \"\(caseName)\""
                }
            }
        }

        let caseLines: [String] = caseLinesArrays.flatMap { $0 }

        let switchBody: String
        if caseLines.isEmpty {
            switchBody = "return \"\""
        } else {
            switchBody = """
            switch self {
            \(caseLines.joined(separator: "\n  "))
            }
            """
        }

        let ext: DeclSyntax = """
        extension \(type.trimmed): RawCaseNameRepresentable {
          public var rawCaseValue: String {
            \(raw: switchBody)
          }
        }
        """

        guard let extensionDecl = ext.as(ExtensionDeclSyntax.self) else {
            return []
        }

        return [extensionDecl]
    }
}
