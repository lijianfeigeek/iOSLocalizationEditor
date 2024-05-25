//
//  WindowController.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 05/03/2019.
//  Copyright © 2019 Igor Kulman. All rights reserved.
//

import Cocoa

// MARK: - 协议定义 - 窗口控制器代理协议

/**
 协议：WindowControllerToolbarDelegate
 用途：宣布用户与工具栏的交互
 */
protocol WindowControllerToolbarDelegate: AnyObject {

    /**
     方法：userDidRequestFolderOpen()
     用途：用户请求打开文件夹时调用
     */
    func userDidRequestFolderOpen()

    /**
     方法：userDidRequestFolderOpen(withPath:)
     用途：用户请求打开特定路径的文件夹时调用
     - Parameter withPath: 文件夹路径
     */
    func userDidRequestFolderOpen(withPath: String)

    /**
     方法：userDidRequestFilterChange(filter:)
     用途：用户请求筛选器更改时调用
     - Parameter filter: 新筛选器设置
     */
    func userDidRequestFilterChange(filter: Filter)

    /**
     方法：userDidRequestSearch(searchTerm:)
     用途：用户请求搜索时调用
     - Parameter searchTerm: 新搜索词
     */
    func userDidRequestSearch(searchTerm: String)

    /**
     方法：userDidRequestLocalizationGroupChange(group:)
     用途：用户请求本地化组更改时调用
     - Parameter group: 新本地化组标题
     */
    func userDidRequestLocalizationGroupChange(group: String)

    /**
     方法：userDidRequestAddNewTranslation()
     用途：用户请求添加新翻译时调用
     */
    func userDidRequestAddNewTranslation()

    /**
     方法：userDidRequestReloadData()
     用途：用户请求重新加载所选文件夹时调用
     */
    func userDidRequestReloadData()
}

// MARK: - 类定义
final class WindowController: NSWindowController {

    // MARK: - IBOutlet 属性

    // 打开按钮
    @IBOutlet private weak var openButton: NSToolbarItem!

    // 搜索文本框
    @IBOutlet private weak var searchField: NSSearchField!

    // 选择按钮
    @IBOutlet private weak var selectButton: NSPopUpButton!

    // 筛选按钮
    @IBOutlet private weak var filterButton: NSPopUpButton!

    // 新建按钮
    @IBOutlet private weak var newButton: NSToolbarItem!

    // MARK: - Properties

    weak var delegate: WindowControllerToolbarDelegate?

    // MARK: - 系统回调方法
    override func windowDidLoad() {
        super.windowDidLoad()
        // 在window加载完成后进行UI和数据的设置
        setupUI()
        setupSearch()
        setupFilter()
        setupMenu()
        setupDelegates()
    }

    // MARK: - 动作方法
        
    // 打开文件夹
    func openFolder(withPath path: String) {
        delegate?.userDidRequestFolderOpen(withPath: path)
    }

    // MARK: - 私有方法

    // 设置UI
    private func setupUI() {
        // 设置openButton的图片和toolTip
        openButton.image = NSImage(named: NSImage.folderName)
        openButton.toolTip = "open_folder".localized
        // 设置其他控件的toolTip
        searchField.toolTip = "search".localized
        filterButton.toolTip = "filter".localized
        selectButton.toolTip = "string_table".localized
        newButton.toolTip = "new_translation".localized
    }

    // 设置搜索栏
    private func setupSearch() {
        // 设置代理和初始值
        searchField.delegate = self
        searchField.stringValue = ""

        // 让搜索栏失去焦点
        _ = searchField.resignFirstResponder()
    }

    // 设置筛选器
    private func setupFilter() {
        // 清空menu
        filterButton.menu?.removeAllItems()

        // 遍历Filter枚举，添加menuItem
        for option in Filter.allCases {
            let item = NSMenuItem(title: "\(option.description)".capitalizedFirstLetter, action: #selector(WindowController.filterAction(sender:)), keyEquivalent: "")
            item.tag = option.rawValue
            filterButton.menu?.addItem(item)
        }
    }

    // 设置Menu
    private func setupMenu() {
        // 获取AppDelegate，设置openFolderMenuItem和reloadMenuItem的action
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.openFolderMenuItem.action = #selector(WindowController.openFolderAction(_:))
        appDelegate.reloadMenuItem.action = #selector(WindowController.reloadDataAction(_:))
    }

    // 启用控件
    private func enableControls() {
        // 启用所有控件
        searchField.isEnabled = true
        filterButton.isEnabled = true
        selectButton.isEnabled = true
        newButton.isEnabled = true
    }

    // 设置代理
    private func setupDelegates() {
        // 获取window的contentViewController，转换为ViewController，设置delegate
        guard let mainViewController = window?.contentViewController as? ViewController else {
            fatalError("Broken window hierarchy")
        }

        // 设置ViewController作为toolbar的delegate
        mainViewController.delegate = self

        // 设置ViewController的delegate
        self.delegate = mainViewController
    }

    // MARK: - 动作

    // selectAction 方法的功能是：根据用户点击的按钮名称，触发本地化组切换事件。
    // sender: NSMenuItem 参数是被点击的按钮对象，从按钮对象中获取按钮名称 groupName。
    // groupName 传递给代理对象，通过代理方法 userDidRequestLocalizationGroupChange，完成本地化组切换。

    @objc private func selectAction(sender: NSMenuItem) {
        let groupName = sender.title
        delegate?.userDidRequestLocalizationGroupChange(group: groupName)
    }

    // 筛选器选择时被调用
    @objc private func filterAction(sender: NSMenuItem) {
        // 根据tag获取Filter，调用代理方法
        guard let filter = Filter(rawValue: sender.tag) else {
            return
        }

        delegate?.userDidRequestFilterChange(filter: filter)
    }

    // 打开文件夹被调用
    @IBAction private func openFolder(_ sender: Any) {
        delegate?.userDidRequestFolderOpen()
    }

    // 新建翻译被调用
    @IBAction private func addAction(_ sender: Any) {
        // 如果新建按钮被禁用，则直接返回
        guard newButton.isEnabled else {
            return
        }

        // 调用代理方法
        delegate?.userDidRequestAddNewTranslation()
    }

    // 打开文件夹菜单被调用
    @objc private func openFolderAction(_ sender: NSMenuItem) {
        delegate?.userDidRequestFolderOpen()
    }

    // 刷新数据被调用
    @objc private func reloadDataAction(_ sender: NSMenuItem) {
        // 调用代理方法
        delegate?.userDidRequestReloadData()
    }
}

// MARK: - NSSearchFieldDelegate

extension WindowController: NSSearchFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        delegate?.userDidRequestSearch(searchTerm: searchField.stringValue)
    }
}

// MARK: - ViewControllerDelegate

extension WindowController: ViewControllerDelegate {
    /**
     Invoked when localization groups should be set in the toolbar's dropdown list
     */
    func shouldSetLocalizationGroups(groups: [LocalizationGroup]) {
        selectButton.menu?.removeAllItems()
        groups.map({ NSMenuItem(title: $0.name, action: #selector(WindowController.selectAction(sender:)), keyEquivalent: "") }).forEach({ selectButton.menu?.addItem($0) })
    }

    /**
     Invoiked when search and filter should be reset in the toolbar
     */
    func shouldResetSearchTermAndFilter() {
        setupSearch()
        setupFilter()

        delegate?.userDidRequestSearch(searchTerm: "")
        delegate?.userDidRequestFilterChange(filter: .all)
    }

    /**
     Invoked when localization group should be selected in the toolbar's dropdown list
     */
    func shouldSelectLocalizationGroup(title: String) {
        enableControls()
        selectButton.selectItem(at: selectButton.indexOfItem(withTitle: title))
    }
}
