//
//  Assembly+Clip.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Combine

extension Assembly {
    func getMainViewModel() -> MainViewModel {
        guard let model: MainViewModel = get() else {
            let mainModel = MainViewModel(sdk: services.tangemSdk,
                                          imageLoaderService: services.imageLoaderService,
                                          userPrefsService: services.userPrefsService,
                                          assembly: services.assembly)
            store(mainModel, isResetable: true)
            return mainModel
        }
        
        return model
    }
    
    // MARK: Card model
    func makeCardModel(from info: CardInfo) -> CardViewModel {
        let vm = CardViewModel(cardInfo: info)
        vm.assembly = self
        vm.tangemSdk = services.tangemSdk
        //vm.updateState()
        return vm
    }
    
    func updateAppClipCard(with batch: String?, fullLink: String) {
        let mainModel: MainViewModel? = get()
        mainModel?.updateCardBatch(batch, fullLink: fullLink)
    }
    
    private func get<T>(key: String) -> T? {
        let val = modelsStorage[key]
        return val as? T
    }
    
    private func get<T>() -> T? {
        let key = String(describing: type(of: T.self))
        return get(key: key)
    }
    
}
