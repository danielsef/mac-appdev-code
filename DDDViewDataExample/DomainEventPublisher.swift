import Foundation

private struct DomainEventPublisherStatic {
    static var singleton: DomainEventPublisher? = nil
    static var onceToken: dispatch_once_t = 0
}

public class DomainEventPublisher {
    
    public class var sharedInstance: DomainEventPublisher {
        
        if !hasValue(DomainEventPublisherStatic.singleton) {
            dispatch_once(&DomainEventPublisherStatic.onceToken) {
                self.setSharedInstance(DomainEventPublisher())
            }
        }
        
        return DomainEventPublisherStatic.singleton!
    }
    
    /// Reset the static `sharedInstance`, for example for testing
    public class func resetSharedInstance() {
        
        DomainEventPublisherStatic.singleton = nil
        DomainEventPublisherStatic.onceToken = 0
    }
    
    public class func setSharedInstance(instance: DomainEventPublisher) {
        
        DomainEventPublisherStatic.singleton = instance
    }

    let notificationCenter: NSNotificationCenter
    
    public convenience init() {
        
        self.init(notificationCenter: NSNotificationCenter.defaultCenter())
    }
    
    public init(notificationCenter: NSNotificationCenter) {
        
        self.notificationCenter = notificationCenter
    }
    

    //MARK: -
    //MARK: Event Publishing and Subscribing
    
    public func publish<T: DomainEvent>(event: T) {
        
        notificationCenter.postNotification(notification(event))
    }
    
    public func subscribe<T: DomainEvent>(eventKind: T.Type, usingBlock block: (T!) -> Void) -> DomainEventSubscription {
        
        let mainQueue = NSOperationQueue.mainQueue()
        
        return self.subscribe(eventKind, queue: mainQueue, usingBlock: block)
    }
    
    public func subscribe<T: DomainEvent>(eventKind: T.Type, queue: NSOperationQueue, usingBlock block: (T!) -> Void) -> DomainEventSubscription {
        
        let eventName: String = T.eventName
        let observer = notificationCenter.addObserverForName(eventName, object: nil, queue: queue) {
            notification in
            
            let userInfo = notification.userInfo!
            let event: T = T(userInfo: userInfo)
            block(event)
        }
        
        return DomainEventSubscription(observer: observer, eventPublisher: self)
    }
    
    public func unsubscribe(subscriber: AnyObject) {
        
        notificationCenter.removeObserver(subscriber)
    }
}
