//
//  WarningsContainer.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class WarningsContainer: ObservableObject {
    @Published var criticals: [TapWarning]
    @Published var warnings: [TapWarning]
    @Published var infos: [TapWarning]
    
    init(criticals: [TapWarning] = [], warnings: [TapWarning] = [], infos: [TapWarning] = []) {
        self.criticals = criticals
        self.warnings = warnings
        self.infos = infos
    }
    
    func add(_ warning: TapWarning) {
        switch warning.priority {
        case .critical:
            if criticals.contains(warning) { return }
            
            criticals.append(warning)
            
        case .warning:
            if warnings.contains(warning) { return }
            
            warnings.append(warning)
            
        case .info: 
            if infos.contains(warning) { return }
            
            infos.append(warning)
        }
    }
    
    func add(_ warnings: [TapWarning]) {
        warnings.forEach { add($0) }
    }
    
    func addWarning(for event: WarningEvent) {
        add(event.warning)
    }
    
    func warning(at index: Int, with priority: WarningPriority) -> TapWarning? {
        var warning: TapWarning?
        switch priority {
        case .info:
            if index < infos.count {
                warning = infos[index]
            }
        case .critical:
            if index < criticals.count {
                warning = criticals[index]
            }
        case .warning:
            if index < warnings.count {
                warning = warnings[index]
            }
        }
        return warning
    }
    
    func remove(_ warning: TapWarning) {
        switch warning.priority {
        case .critical:
            criticals.removeAll(where: { $0 == warning })
        case .warning:
            warnings.removeAll(where: { $0 == warning })
        case .info:
            infos.removeAll(where: { $0 == warning })
        }
    }
}
