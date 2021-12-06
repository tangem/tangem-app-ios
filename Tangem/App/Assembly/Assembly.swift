//
//  Assembly.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class Assembly: ObservableObject {
    #if !CLIP
    public let services: AppServicesAssembly
    #else
    public let services: ServicesAssembly
    #endif
    
    let isPreview: Bool
    
    var modelsStorage = [String : Any]()
    var persistenceStorage = [String : Any]()
    
    init(isPreview: Bool = false) {
        #if CLIP
        services = ServicesAssembly()
        #else
        services = AppServicesAssembly()
        #endif
        
        self.isPreview = isPreview
        
        services.assembly = self
        
        #if !CLIP
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            self.services.validatedCards.clean()
        }
        #endif
    }
    
    deinit {
        print("Assembly deinit")
    }
    
    func store<T>(_ object: T, isResetable: Bool) {
        let key = String(describing: type(of: T.self))
        store(object, with: key, isResetable: isResetable)
    }
    
    func store<T>(_ object: T, with key: String, isResetable: Bool) {
        //print(key)
        if isResetable {
            modelsStorage[key] = object
        } else {
            persistenceStorage[key] = object
        }
    }
    
    public func reset(key: String) {
        modelsStorage.removeValue(forKey: key)
    }
}
