//
//  AsyncOperation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation

enum Result<Value> {
    case success(Value)
    case failure(Error)
}

public class AsynchronousOperation: Operation {
    
    @objc private enum OperationState: Int {
        case ready
        case executing
        case finished
    }
    
    private let stateQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! + ".rw.state", attributes: .concurrent)
    
    private var _state: OperationState = .ready
    
    @objc private dynamic var state: OperationState {
        get { return stateQueue.sync { _state } }
        set { stateQueue.sync(flags: .barrier) { _state = newValue } }
    }
    
    open         override var isReady:        Bool { return state == .ready && super.isReady }
    public final override var isExecuting:    Bool { return state == .executing }
    public final override var isFinished:     Bool { return state == .finished }
    
    open override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        if ["isReady", "isFinished", "isExecuting"].contains(key) {
            return [#keyPath(state)]
        }
        
        return super.keyPathsForValuesAffectingValue(forKey: key)
    }
    
    public final override func start() {
        if isCancelled {
            finish()
            return
        }
        
        state = .executing
        
        main()
    }
    
    open override func main() {
        fatalError("Subclasses must implement `main`.")
    }
    
    public final func finish() {
        if isExecuting { state = .finished }
    }
}
