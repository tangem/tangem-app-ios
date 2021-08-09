//
//  Assembly.swift
//  Tangem Tap
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
    
    // MARK: - Private funcs
    
    func store<T>(_ object: T ) {
        let key = String(describing: type(of: T.self))
        store(object, with: key)
    }
    
    func store<T>(_ object: T, with key: String) {
        //print(key)
        modelsStorage[key] = object
    }
    
    public func reset(key: String) {
        modelsStorage.removeValue(forKey: key)
    }
}
