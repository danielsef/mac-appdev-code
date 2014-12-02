//
//  ItemViewController.swift
//  DDDViewDataExample
//
//  Created by Christian Tietze on 17.11.14.
//  Copyright (c) 2014 Christian Tietze. All rights reserved.
//

import Cocoa
import XCTest

import DDDViewDataExample

class TestBoxNode: BoxNode {
    convenience init() {
        self.init(boxId: BoxId(0))
        
        title = "title"
        count = 1234
        children = []
        isLeaf = false
    }
    
    convenience init(title: String) {
        self.init()
        self.title = title
    }
}


class EventHandlerStub: HandlesItemListEvents {
    func provisionNewBoxId() -> BoxId {
        return BoxId(0)
    }
    
    func provisionNewItemId(inBox boxId: BoxId) -> ItemId {
        return ItemId(0)
    }
    
    func changeBoxTitle(boxId: BoxId, title: String) {
        // no op
    }
    
    func changeItemTitle(itemId: ItemId, title: String, inBox boxId: BoxId) {
        // no op
    }
    
    func removeItem(itemId: ItemId, fromBox boxId: BoxId) {
        // no op
    }
    
    func removeBox(boxId: BoxId) {
        // no op
    }
}


class ItemViewControllerTests: XCTestCase {
    var viewController: ItemViewController!
    var testEventHandler: EventHandlerStub! = EventHandlerStub()
    
    override func setUp() {
        super.setUp()
        
        let windowController = ItemManagementWindowController()
        windowController.loadWindow()
        viewController = windowController.itemViewController
        viewController.eventHandler = testEventHandler
    }
    
    override func tearDown() {
        
        super.tearDown()
    }
    
    func boxNodes() -> [NSTreeNode] {
        return viewController.itemsController.arrangedObjects.childNodes!! as [NSTreeNode]
    }
    
    func boxNodeCount() -> Int {
        return boxNodes().count
    }
    
    func boxAtIndex(index: Int) -> NSTreeNode {
        return boxNodes()[index]
    }
    
    func itemTreeNode(atBoxIndex boxIndex: Int, itemIndex: Int) -> NSTreeNode {
        let boxNode: NSTreeNode = boxAtIndex(boxIndex)
        return boxNode.childNodes![itemIndex] as NSTreeNode
    }
    
    
    //MARK: Nib Setup
    
    func testView_IsLoaded() {
        XCTAssertNotNil(viewController.view, "view should be set in Nib")
        XCTAssertEqual(viewController.view.className, "NSOutlineView", "view should be outline view")
        XCTAssertEqual(viewController.view, viewController.outlineView, "tableView should be alternative to view")
    }

    func testOutlineViewColumns_NamedProperly() {
        let outlineView = viewController.outlineView
        
        XCTAssertNotNil(outlineView.tableColumnWithIdentifier(kColumnNameTitle), "outline should include title column")
        XCTAssertNotNil(outlineView.tableColumnWithIdentifier(kColumnNameCount), "outline should include count column")
    }
    
    func testItemsController_IsConnected() {
        XCTAssertNotNil(viewController.itemsController)
    }
    
    func testItemsController_PreservesSelection() {
        XCTAssertTrue(viewController.itemsController.preservesSelection)
    }
    
    func testItemsController_CocoaBindings() {
        let controller = viewController.itemsController
        let outlineView = viewController.outlineView
        let titleColumn = outlineView.tableColumnWithIdentifier(kColumnNameTitle)
        let countColumn = outlineView.tableColumnWithIdentifier(kColumnNameCount)
        
        XCTAssertTrue(hasBinding(controller, binding: NSSortDescriptorsBinding, to: viewController, throughKeyPath: "self.itemsSortDescriptors"))
        XCTAssertTrue(hasBinding(outlineView, binding: NSContentBinding, to: controller, throughKeyPath: "arrangedObjects"))
        
        XCTAssertTrue(hasBinding(titleColumn!, binding: NSValueBinding, to: controller, throughKeyPath: "arrangedObjects.title"))
        XCTAssertTrue(hasBinding(countColumn!, binding: NSValueBinding, to: controller, throughKeyPath: "arrangedObjects.count"))
    }
    
    func testAddBoxButton_IsConnected() {
        XCTAssertNotNil(viewController.addBoxButton)
    }
    
    func testAddBoxButton_IsWiredToAction() {
        XCTAssertEqual(viewController.addBoxButton.action, Selector("addBox:"))
    }
    
    func testAddItemButton_IsConnected() {
        XCTAssertNotNil(viewController.addItemButton)
    }
    
    func testAddItemButton_IsWiredToAction() {
        XCTAssertEqual(viewController.addItemButton.action, Selector("addItem:"))
    }
    
    func testAddItemButton_CocoaBindings() {
        XCTAssertTrue(hasBinding(viewController.addItemButton, binding: NSEnabledBinding, to: viewController.itemsController, throughKeyPath: "selectionIndexPath", transformingWith: "NSIsNotNil"), "enable button in virtue of itemsController selection != nil")
    }
    
    func testRemoveButton_IsConnected() {
        XCTAssertNotNil(viewController.removeButton)
    }

    func testRemoveButton_IsWiredToAction() {
        XCTAssertEqual(viewController.removeButton.action, Selector("removeSelectedObject:"))
    }
    
    func testRemoveButton_CocoaBindings() {
        XCTAssertTrue(hasBinding(viewController.removeButton, binding: NSEnabledBinding, to: viewController.itemsController, throughKeyPath: "selectionIndexPath", transformingWith: "NSIsNotNil"), "enable button in virtue of itemsController selection != nil")
    }
    
    func testItemRowView_TitleCell_SetUpProperly() {
        viewController.itemsController.addObject(TestBoxNode())
        
        let titleCellView: NSTableCellView = viewController.outlineView.viewAtColumn(0, row: 0, makeIfNecessary: true) as NSTableCellView
        let titleTextField = titleCellView.textField!
        XCTAssertTrue(titleTextField.editable)
        XCTAssertTrue(hasBinding(titleTextField, binding: NSValueBinding, to: titleCellView, throughKeyPath: "objectValue.title"))
    }
    
    func testItemRowView_CountCell_SetUpProperly() {
        viewController.itemsController.addObject(TestBoxNode())
        
        let countCellView: NSTableCellView = viewController.outlineView.viewAtColumn(1, row: 0, makeIfNecessary: true) as NSTableCellView
        let countTextField = countCellView.textField!
        XCTAssertFalse(countTextField.editable, "count text field should not be editable")
        XCTAssertTrue(hasBinding(countTextField, binding: NSValueBinding, to: countCellView, throughKeyPath: "objectValue.count"))
    }
    
    
    //MARK: - 
    //MARK: Adding Boxes

    func testInitially_TreeIsEmpty() {
        XCTAssertEqual(boxNodeCount(), 0, "start with empty tree")
    }
    
    func testInitially_AddItemButtonIsDisabled() {
        XCTAssertFalse(viewController.addItemButton.enabled, "disable item button without boxes")
    }
    
    func testAddBox_WithEmptyList_AddsNode() {
        viewController.addBox(self)
        
        XCTAssertEqual(boxNodeCount(), 1, "adds item to tree")
    }
    
    func testAddBox_WithEmptyList_EnablesAddItemButton() {
        viewController.addBox(self)
        
        XCTAssertTrue(viewController.addItemButton.enabled, "enable item button by adding boxes")
    }
    
    func testAddBox_WithExistingBox_OrdersThemByTitle() {
        // Given
        let bottomItem = TestBoxNode(title: "ZZZ Should be at the bottom")
        viewController.itemsController.addObject(bottomItem)
        
        let existingNode: NSObject = boxAtIndex(0)
        
        // When
        viewController.addBox(self)
        
        // Then
        XCTAssertEqual(boxNodeCount(), 2, "add node to existing one")
        let lastNode: NSObject = boxAtIndex(1)
        XCTAssertEqual(existingNode, lastNode, "new node should be put before existing one")
    }

    func testAddBox_Twice_SelectsSecondBox() {
        let treeController = viewController.itemsController
        treeController.addObject(TestBoxNode(title: "first"))
        treeController.addObject(TestBoxNode(title: "second"))
        
        XCTAssertTrue(treeController.selectedNodes.count > 0, "should auto-select")
        let selectedNode: NSTreeNode = treeController.selectedNodes[0] as NSTreeNode
        let item: TreeNode = selectedNode.representedObject as TreeNode
        XCTAssertEqual(item.title, "second", "select latest insertion")
    }
    
    
    //MARK: Adding Items
    
    func testAddItem_WithoutBoxes_DoesNothing() {
        viewController.addItem(self)
        
        XCTAssertEqual(boxNodeCount(), 0, "don't add boxes")
    }
    
    func testAddItem_WithSelectedBox_InsertsItemBelowSelectedBox() {
        // Pre-populate
        let treeController = viewController.itemsController
        treeController.addObject(TestBoxNode(title: "first"))
        treeController.addObject(TestBoxNode(title: "second"))
        
        // Select first node
        let selectionIndexPath = NSIndexPath(index: 0)
        treeController.setSelectionIndexPath(selectionIndexPath)
        let selectedBox = (treeController.selectedNodes[0] as NSTreeNode).representedObject as TreeNode
        XCTAssertEqual(selectedBox.children.count, 0, "box starts empty")
        
        viewController.addItem(self)
        
        // Then
        XCTAssertEqual(selectedBox.children.count, 1, "box contains new child")
        XCTAssertEqual(selectedBox.children[0].isLeaf, true, "child should be item=leaf")
    }
    
    
    //MARK: Displaying Box Data
    
    func testDisplayData_Once_PopulatesTree() {
        let itemId = ItemId(444)
        let itemData = ItemData(itemId: itemId, title: "irrelevant item title")
        let boxId = BoxId(1122)
        let boxData = BoxData(boxId: boxId, title: "irrelevant box title", itemData: [itemData])

        viewController.displayBoxData([boxData])
        
        XCTAssertEqual(boxNodeCount(), 1)
        let soleBoxTreeNode = boxAtIndex(0)
        let boxNode = soleBoxTreeNode.representedObject as BoxNode
        XCTAssertEqual(boxNode.boxId, boxId)
        
        let itemNodes = soleBoxTreeNode.childNodes! as [NSTreeNode]
        XCTAssertEqual(itemNodes.count, 1)
        if let soleItemTreeNode = itemNodes.first {
            let itemNode = soleItemTreeNode.representedObject as ItemNode
            XCTAssertEqual(itemNode.itemId, itemId)
        }
    }
    
    func testDisplayData_Twice_ReplacedNodes() {
        let itemId = ItemId(444)
        let itemData = ItemData(itemId: itemId, title: "irrelevant item title")
        let boxId = BoxId(1122)
        let boxData = BoxData(boxId: boxId, title: "irrelevant box title", itemData: [itemData])
        
        viewController.displayBoxData([boxData])
        viewController.displayBoxData([boxData])
        
        XCTAssertEqual(boxNodeCount(), 1)
        XCTAssertEqual(boxAtIndex(0).childNodes!.count, 1)
    }

    
    //MARK: -
    //MARK: Removing Boxes
    
    func testRemoveBox_RemovesNodeFromTree() {
        let treeController = viewController.itemsController
        treeController.addObject(TestBoxNode(title: "the box"))
        treeController.setSelectionIndexPath(NSIndexPath(index: 0))
        XCTAssertEqual(boxNodeCount(), 1)
        
        viewController.removeSelectedObject(self)
        
        XCTAssertEqual(boxNodeCount(), 0)
    }
    
    func testRemoveItem_RemovesNodeFromTree() {
        let treeController = viewController.itemsController
        let rootNode = TestBoxNode(title: "the box")
        rootNode.children = [TestBoxNode(title: "the item")]
        treeController.addObject(rootNode)
        treeController.setSelectionIndexPath(NSIndexPath(index: 0).indexPathByAddingIndex(0))
        XCTAssertEqual(boxNodes().first!.childNodes!.count, 1)
        
        viewController.removeSelectedObject(self)
        
        XCTAssertEqual(boxNodeCount(), 1)
        XCTAssertEqual(boxNodes().first!.childNodes!.count, 0)
    }

}
