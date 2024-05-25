//
//  ViewController.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//

// MARK: - 视图控制器协议 (ViewController 协议)
import Cocoa
/**
// 此协议用于通知工具栏的更改。因为视图控制器本身没有直接访问工具栏（由 WindowController 处理）
*/
protocol ViewControllerDelegate: AnyObject {
    /**
     // 当本地化组应设置在工具栏的下拉列表中时调用
     */
    func shouldSetLocalizationGroups(groups: [LocalizationGroup])

    /**
     // 当在工具栏中重置搜索和筛选器时调用
     */
    func shouldResetSearchTermAndFilter()

    /**
     // 当在工具栏的下拉列表中选择本地化组时调用
     */
    func shouldSelectLocalizationGroup(title: String)
}

final class ViewController: NSViewController {
    // MARK: - 固定列（Fixed Column）
    enum FixedColumn: String {
        // 列的类型，可以是 key 或 actions
        case key // 表示该列为 key
        case actions // 表示该列为 actions
    }

    // MARK: - 控件 Outlet 连接

    // 表格视图 Outlet，用于在界面上显示数据
    @IBOutlet private weak var tableView: NSTableView!

    // 进度条 Outlet，用于显示当前操作的进度
    @IBOutlet private weak var progressIndicator: NSProgressIndicator!

    // MARK: - Properties

    //Delegate 变量，用于Delegate设计模式，可选类型
    weak var delegate: ViewControllerDelegate?

    //当前的过滤器，默认为 .all
    private var currentFilter: Filter = .all

    //当前的搜索词，默认为 ""
    private var currentSearchTerm: String = ""

    //数据源，负责提供数据
    private let dataSource = LocalizationsDataSource()

    //是否已经显示过AddViewController，防止重复显示
    private var presendedAddViewController: AddViewController?

    //当前打开的文件夹URL
    private var currentOpenFolderUrl: URL?

    override func viewDidLoad() {
        super.viewDidLoad()

        //在这里进行数据的初始化设置
        setupData()
    }

    // MARK: - Setup

    // setupData() 函数用于设置表格视图 (tableView) 所需的数据
    private func setupData() {
        
        // 1. 注册表格视图单元格标识符 (cellIdentifier)
        // 在本例中，我们注册了三种单元格的标识符：KeyCell、LocalizationCell 和 ActionsCell
        let cellIdentifiers = [KeyCell.identifier, LocalizationCell.identifier, ActionsCell.identifier]
        cellIdentifiers.forEach { identifier in
            // 加载 Nib 文件并注册标识符
            // (注意：NSNib.init(nibNamed:bundle:) 方法将在 Nib 文件中查找相应的标识符)
            let cell = NSNib(nibNamed: identifier, bundle: nil)
            tableView.register(cell, forIdentifier: NSUserInterfaceItemIdentifier(rawValue: identifier))
        }
        
        // 2. 为表格视图设置代理 (delegate) 和数据源 (dataSource)
        // (注意：delegate 和 dataSource 用于处理表格视图的交互和数据展示)
        tableView.delegate = self
        tableView.dataSource = dataSource
        
        // 3. 启用列宽度调整
        tableView.allowsColumnResizing = true
        
        // 4. 启用自动行高
        tableView.usesAutomaticRowHeights = true
        
        // 5. 设置选择高亮样式
        // (注意：.none 表示不对选中的行进行高亮显示)
        tableView.selectionHighlightStyle = .none
    }

    private func reloadData(with languages: [String], title: String?) {
        // 重置搜索条件和筛选器
        delegate?.shouldResetSearchTermAndFilter()

        // 获取应用程序的名称
        let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String

        // 设置窗口标题和子标题（根据 macOS 版本）
        if #available(macOS 11, *) {
            view.window?.title = appName
            view.window?.subtitle = title ?? ""
        } else {
            view.window?.title = title.flatMap({ "\(appName) [\($0)]" }) ?? appName
        }

        // 获取当前表格列，并遍历移除所有列
        let columns = tableView.tableColumns
        columns.forEach {
            self.tableView.removeTableColumn($0)
        }

        // 重新加载数据，避免布局崩溃
        tableView.reloadData()

        // 添加 "key" 列
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(FixedColumn.key.rawValue))
        column.title = "key".localized
        tableView.addTableColumn(column)

        // 遍历语言数组，添加相应的列
        languages.forEach { language in
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(language))
            column.title = Flag(languageCode: language).emoji
            column.maxWidth = 460
            column.minWidth = 50
            self.tableView.addTableColumn(column)
        }

        // 添加 "actions" 列
        let actionsColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(FixedColumn.actions.rawValue))
        actionsColumn.title = "actions".localized
        actionsColumn.maxWidth = 48
        actionsColumn.minWidth = 32
        tableView.addTableColumn(actionsColumn)

        // 重新加载数据
        tableView.reloadData()

        // 调整所有列的大小
        tableView.sizeToFit()

        // 适当调整 actions 列的大小
        DispatchQueue.main.async {
            self.tableView.sizeToFit()
            self.tableView.layout()
        }
    }

    // MARK: - 私有函数（Private Functions）

    /// 筛选函数，根据 currentFilter 和 currentSearchTerm 进行数据过滤
    /// - Note: 重新加载 tableView 数据
    private func filter() {
        dataSource.filter(by: currentFilter, searchString: currentSearchTerm)
        tableView.reloadData()
    }

    /// 处理打开文件夹函数
    /// - Parameter url: URL 类型的文件夹路径
    private func handleOpenFolder(_ url: URL) {
        // 开始进度条动画
        self.progressIndicator.startAnimation(self)

        // 加载数据，并在加载完成后执行闭包中的代码
        self.dataSource.load(folder: url) { [unowned self] languages, title, localizationFiles in
            // 设置当前已打开的文件夹 URL
            self.currentOpenFolderUrl = url
            
            // 重新加载数据，传入 languages 和 title
            self.reloadData(with: languages, title: title)
            
            // 停止进度条动画
            self.progressIndicator.stopAnimation(self)

            // 如果 title 存在，则执行以下操作
            if let title = title {
                // 委托方设置 LocalizationGroups
                self.delegate?.shouldSetLocalizationGroups(groups: localizationFiles)
                
                // 委托方选择 LocalizationGroup
                self.delegate?.shouldSelectLocalizationGroup(title: title)
            }
        }
    }

    // MARK: - 打开文件夹

    /// 打开文件夹，可以是指定路径或通过对话框选择
    private func openFolder(forPath path: String? = nil) {
        // 如果已提供路径，直接处理并返回
        if let path = path {
            handleOpenFolder(URL(fileURLWithPath: path))
            return
        }

        // 创建并配置 NSOpenPanel 对话框
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false // 只允许选择一个目录
        openPanel.canChooseDirectories = true  // 允许选择目录
        openPanel.canCreateDirectories = true  // 允许创建目录
        openPanel.canChooseFiles = false       // 不允许选择文件

        // 显示对话框并处理用户选择
        openPanel.begin { result -> Void in
            // 如果点击了“取消”或未选择目录，直接返回
            guard result.rawValue == NSApplication.ModalResponse.OK.rawValue, let url = openPanel.url else {
                return
            }
            // 选择了目录，处理打开目录
            self.handleOpenFolder(url)
        }
    }
}

// MARK: - NSTableViewDelegate

extension ViewController: NSTableViewDelegate {
    // 该方法用于自定义 NSTableView 中的每个单元格
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        // 获取当前单元格的标识符
        guard let identifier = tableColumn?.identifier else {
            return nil
        }

        // 根据不同的标识符，返回不同的单元格
        switch identifier.rawValue {
        case FixedColumn.key.rawValue:
            // 创建 KeyCell 单元格，并设置相应的属性
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: KeyCell.identifier), owner: self)! as! KeyCell
            cell.key = dataSource.getKey(row: row)
            cell.message = dataSource.getMessage(row: row)
            return cell
        case FixedColumn.actions.rawValue:
            // 创建 ActionsCell 单元格，并设置相应的属性
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: ActionsCell.identifier), owner: self)! as! ActionsCell
            cell.delegate = self
            cell.key = dataSource.getKey(row: row)
            return cell
        default:
            // 创建 LocalizationCell 单元格，并设置相应的属性
            let language = identifier.rawValue
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: LocalizationCell.identifier), owner: self)! as! LocalizationCell
            cell.delegate = self
            cell.language = language
            cell.value = row < dataSource.numberOfRows(in: tableView) ? dataSource.getLocalization(language: language, row: row) : nil
            return cell
        }
    }
}

// MARK: - LocalizationCellDelegate

extension ViewController: LocalizationCellDelegate {
    // 当用户更新了本地化字符串时，该方法会被调用
    func userDidUpdateLocalizationString(language: String, key: String, with value: String, message: String?) {
        dataSource.updateLocalization(language: language, key: key, with: value, message: message)
    }

    // 当文本编辑结束时，该方法会被调用
    func controlTextDidEndEditing(_ obj: Notification) {
        // 获取当前被编辑的视图、文本移动方向等信息
        guard let view = obj.object as? NSView, let textMovementInt = obj.userInfo?["NSTextMovement"] as? Int, let textMovement = NSTextMovement(rawValue: textMovementInt) else {
            return
        }

        // 获取当前被编辑单元格的列和行索引
        let columnIndex = tableView.column(for: view)
        let rowIndex = tableView.row(for: view)

        // 计算新的列和行索引
        var newRowIndex = rowIndex
        var newColumnIndex = columnIndex

        switch textMovement {
        case .tab:
            // 按 Tab 键时，切换到下一个单元格
            if columnIndex + 1 >= tableView.numberOfColumns - 1 {
                newRowIndex = rowIndex + 1
                newColumnIndex = 1
            } else {
                newColumnIndex = columnIndex + 1
                newRowIndex = rowIndex
            }
            if newRowIndex >= tableView.numberOfRows {
                // 如果新的行索引超出了表格的范围，则不做任何操作
                return
            }
        case .backtab:
            // 按 Shift + Tab 键时，切换到上一个单元格
            if columnIndex - 1 <= 0 {
                newRowIndex = rowIndex - 1
                newColumnIndex = tableView.numberOfColumns - 2
            } else {
                newColumnIndex = columnIndex - 1
                newRowIndex = rowIndex
            }
            if newRowIndex < 0 {
                // 如果新的行索引小于 0，则不做任何操作
                return
            }
        default:
            // 如果文本没有编辑结束，则不做任何操作
            return
        }

        DispatchQueue.main.async { [weak self] in
            // 切换到新的单元格
            self?.tableView.editColumn(newColumnIndex, row: newRowIndex, with: nil, select: true)
        }
    }
}

// MARK: - ActionsCellDelegate

extension ViewController: ActionsCellDelegate {
    // 用户请求删除指定键的本地化字符串时，会调用该方法
    func userDidRequestRemoval(of key: String) {
        // 删除指定键的本地化字符串
        dataSource.deleteLocalization(key: key)

        // 刷新表格视图，同时保留滚动条的位置
        let rect = tableView.visibleRect
        filter()
        tableView.scrollToVisible(rect)
    }
}

// MARK: - WindowControllerToolbarDelegate

// 扩展 ViewController，遵循 WindowControllerToolbarDelegate 协议
extension ViewController: WindowControllerToolbarDelegate {
    
    /**
     * 当用户请求添加新的翻译时调用
     */
    // 用户点击工具栏的 "+" 按钮时，会调用该方法，弹出 AddViewController 视图控制器，用于添加新的翻译
    func userDidRequestAddNewTranslation() {
        let addViewController = storyboard!.instantiateController(withIdentifier: "Add") as! AddViewController
        addViewController.delegate = self
        presendedAddViewController = addViewController
        presentAsSheet(addViewController)
    }

    /**
     * 当用户请求过滤器更改时调用
     *
     * - Parameter filter: 新的过滤器设置
     */
    // 用户在界面上更改了某些筛选条件，会调用该方法，进行相应的筛选
    func userDidRequestFilterChange(filter: Filter) {
        guard currentFilter != filter else {
            return
        }

        currentFilter = filter
        self.filter()
    }

    /**
     * 当用户请求搜索时调用
     *
     * - Parameter searchTerm: 新的搜索词
     */
    // 用户在界面上输入搜索关键字，会调用该方法，进行相应的搜索
    func userDidRequestSearch(searchTerm: String) {
        guard currentSearchTerm != searchTerm else {
            return
        }

        currentSearchTerm = searchTerm
        filter()
    }

    /**
     * 当用户请求更改所选的本地化组时调用
     *
     * - Parameter group: 新的本地化组标题
     */
    // 用户在界面上选择不同的本地化组，会调用该方法，重新加载数据
    func userDidRequestLocalizationGroupChange(group: String) {
        let languages = dataSource.selectGroupAndGetLanguages(for: group)
        reloadData(with: languages, title: group)
    }

    /**
     * 当用户请求打开文件夹时调用
     */
    // 用户点击工具栏的 "Open" 按钮，会调用该方法，打开一个文件选择器，用于选择要打开的文件夹
    func userDidRequestFolderOpen() {
        openFolder()
    }

    /**
     * 当用户请求打开特定路径的文件夹时调用
     */
    // 用户在界面上输入特定的文件夹路径，会调用该方法，打开指定的文件夹
    func userDidRequestFolderOpen(withPath path: String) {
        openFolder(forPath: path)
    }

    /**
     * 当用户请求重新加载所选文件夹时调用
     */
    // 用户点击工具栏的 "Reload" 按钮，会调用该方法，重新加载所选的文件夹
    func userDidRequestReloadData() {
        guard let currentOpenFolderUrl = currentOpenFolderUrl else {
            return
        }
        handleOpenFolder(currentOpenFolderUrl)

    }
}

// MARK: - AddViewControllerDelegate

extension ViewController: AddViewControllerDelegate {
    // 用户点击取消时，会调用该方法
    func userDidCancel() {
        // 关闭当前的 AddViewController
        dismiss()
    }

    // 用户点击添加翻译时，会调用该方法
    func userDidAddTranslation(key: String, message: String?) {
        // 关闭当前的 AddViewController
        dismiss()

        // 添加新的本地化字符串
        dataSource.addLocalizationKey(key: key, message: message)

        // 刷新表格视图
        filter()

        // 如果新添加的本地化字符串的键存在，则滚动到该行
        if let row = dataSource.getRowForKey(key: key) {
            DispatchQueue.main.async {
                self.tableView.scrollRowToVisible(row)
            }
        }
    }

    // 关闭当前的 AddViewController
    private func dismiss() {
        // 获取当前的 AddViewController
        guard let presendedAddViewController = presendedAddViewController else {
            // 如果当前没有 AddViewController，则不做任何操作
            return
        }

        // 关闭当前的 AddViewController
        dismiss(presendedAddViewController)
    }
}
