//
//  UIViewController+Segue.swift
//  SegueKit
//
//  Created by langyanduan on 16/5/24.
//  Copyright © 2016年 seguekit. All rights reserved.
//

import UIKit

class SegueObject {
    class Context {
        let identifier: String
        let type: AnyObject.Type
        let handler: (UIStoryboardSegue, AnyObject?) -> Void
        let removeOnComplete: Bool
        
        init(identifier: String, type: AnyObject.Type, handler: (UIStoryboardSegue, AnyObject?) -> Void, removeOnComplete: Bool) {
            self.identifier = identifier
            self.type = type
            self.handler = handler
            self.removeOnComplete = removeOnComplete
        }
    }
    
    var contexts: [Context] = []
    
    func save(identifier: String, type: AnyObject.Type, handler: (UIStoryboardSegue, AnyObject?) -> Void, removeOnComplete: Bool) -> Context {
        let context = Context(identifier: identifier, type: type, handler: handler, removeOnComplete: removeOnComplete)
        contexts.append(context)
        return context
    }
    
    func removeContext(context: Context) {
        var index: Int?
        for (i, ctx) in contexts.enumerate() {
            if ctx === context {
                index = i
                break
            }
        }
        
        if let index = index {
            contexts.removeAtIndex(index)
        }
    }
    
    func query(identifier: String, type: AnyObject.Type) -> [Context] {
        var list = [Context]()
        for context in contexts {
            if context.identifier == identifier && context.type == type {
                list.append(context)
            }
        }
        return list
    }
}


// MARK:- AOP

private var kSegueObjectKey: Void = ()
extension UIViewController {
    var aop_context: SegueObject {
        if let obj = objc_getAssociatedObject(self, &kSegueObjectKey) as? SegueObject {
            return obj
        }
        let obj = SegueObject()
        objc_setAssociatedObject(self, &kSegueObjectKey, obj, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return obj
    }
    
    @objc dynamic
    func aop_prepare(for segue: UIStoryboardSegue, sender: AnyObject?, and type: AnyObject.Type) {
        guard let identifier = segue.identifier else {
            return
        }
        let list = aop_context.query(identifier, type: type)
        for context in list {
            context.handler(segue, sender)
            
            if context.removeOnComplete {
                aop_context.removeContext(context)
            }
        }
    }
}

// MARK:- Public 

public extension UIViewController {
    public func performSegue(with identifier: String, handler: UIStoryboardSegue -> Void) {
        swz_swizzleIfNeeded()
        let handlerWrapper: (UIStoryboardSegue, AnyObject?) -> Void = { (segue, sender) in
            handler(segue)
        }
        aop_context.save(identifier, type: self.dynamicType, handler: handlerWrapper, removeOnComplete: true)
        performSegueWithIdentifier(identifier, sender: nil)
    }
}
