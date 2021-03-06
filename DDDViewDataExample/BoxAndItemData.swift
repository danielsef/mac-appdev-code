import Foundation

public protocol HandlesItemListEvents: class {
    func createBox()
    func createItem(boxId: BoxId)
    
    func changeBoxTitle(boxId: BoxId, title: String)
    func changeItemTitle(itemId: ItemId, title: String, inBox boxId: BoxId)
    
    func removeBox(boxId: BoxId)
    func removeItem(itemId: ItemId, fromBox boxId: BoxId)
}

public struct BoxData {
    let boxId: BoxId
    let title: String
    let itemData: [ItemData]
    
    public init(boxId: BoxId, title: String) {
        self.init(boxId: boxId, title: title, itemData: [])
    }
    
    public init(boxId: BoxId, title: String, itemData: [ItemData]) {
        self.boxId = boxId
        self.title = title
        self.itemData = itemData
    }
}

public struct ItemData {
    let itemId: ItemId
    let title: String
    var boxId: BoxId?
    
    public init(itemId: ItemId, title: String) {
        self.itemId = itemId
        self.title = title
    }
    
    public init(itemId: ItemId, title: String, boxId: BoxId) {
        self.itemId = itemId
        self.title = title
        self.boxId = boxId
    }
}
