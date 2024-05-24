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
    enum FixedColumn: String {
        case key
        case actions
    }

    // MARK: - Outlets

    @IBOutlet private weak var tableView: NSTableView!
    @IBOutlet private weak var progressIndicator: NSProgressIndicator!

    // MARK: - Properties

    weak var delegate: ViewControllerDelegate?

    private var currentFilter: Filter = .all
    private var currentSearchTerm: String = ""
    private let dataSource = LocalizationsDataSource()
    private var presendedAddViewController: AddViewController?
    private var currentOpenFolderUrl: URL?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupData()
    }

    // MARK: - Setup

    private func setupData() {
        let cellIdentifiers = [KeyCell.identifier, LocalizationCell.identifier, ActionsCell.identifier]
        cellIdentifiers.forEach { identifier in
            let cell = NSNib(nibNamed: identifier, bundle: nil)
            tableView.register(cell, forIdentifier: NSUserInterfaceItemIdentifier(rawValue: identifier))
        }

        tableView.delegate = self
        tableView.dataSource = dataSource
        tableView.allowsColumnResizing = true
        tableView.usesAutomaticRowHeights = true

        tableView.selectionHighlightStyle = .none
    }

    private func reloadData(with languages: [String], title: String?) {
        delegate?.shouldResetSearchTermAndFilter()

        let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        if #available(macOS 11, *) {
            view.window?.title = appName
            view.window?.subtitle = title ?? ""
        } else {
            view.window?.title = title.flatMap({ "\(appName) [\($0)]" }) ?? appName
        }

        let columns = tableView.tableColumns
        columns.forEach {
            self.tableView.removeTableColumn($0)
        }

        // not sure why this is needed but without it autolayout crashes and the whole tableview breaks visually
        tableView.reloadData()

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(FixedColumn.key.rawValue))
        column.title = "key".localized
        tableView.addTableColumn(column)

        languages.forEach { language in
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(language))
            column.title = Flag(languageCode: language).emoji
            column.maxWidth = 460
            column.minWidth = 50
            self.tableView.addTableColumn(column)
        }

        let actionsColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(FixedColumn.actions.rawValue))
        actionsColumn.title = "actions".localized
        actionsColumn.maxWidth = 48
        actionsColumn.minWidth = 32
        tableView.addTableColumn(actionsColumn)

        tableView.reloadData()

        // Also resize the columns:
        tableView.sizeToFit()

        // Needed to properly size the actions column
        DispatchQueue.main.async {
            self.tableView.sizeToFit()
            self.tableView.layout()
        }
    }

    private func filter() {
        dataSource.filter(by: currentFilter, searchString: currentSearchTerm)
        tableView.reloadData()
    }

    private func handleOpenFolder(_ url: URL) {
        self.progressIndicator.startAnimation(self)
        self.dataSource.load(folder: url) { [unowned self] languages, title, localizationFiles in
            self.currentOpenFolderUrl = url
            self.reloadData(with: languages, title: title)
            self.progressIndicator.stopAnimation(self)

            if let title = title {
                self.delegate?.shouldSetLocalizationGroups(groups: localizationFiles)
                self.delegate?.shouldSelectLocalizationGroup(title: title)
            }
        }
    }

    private func openFolder(forPath path: String? = nil) {
        if let path = path {
            handleOpenFolder(URL(fileURLWithPath: path))
            return
        }

        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.canChooseFiles = false
        openPanel.begin { result -> Void in
            guard result.rawValue == NSApplication.ModalResponse.OK.rawValue, let url = openPanel.url else {
                return
            }
            self.handleOpenFolder(url)
        }
    }
}

// MARK: - NSTableViewDelegate

extension ViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let identifier = tableColumn?.identifier else {
            return nil
        }

        switch identifier.rawValue {
        case FixedColumn.key.rawValue:
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: KeyCell.identifier), owner: self)! as! KeyCell
            cell.key = dataSource.getKey(row: row)
            cell.message = dataSource.getMessage(row: row)
            return cell
        case FixedColumn.actions.rawValue:
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: ActionsCell.identifier), owner: self)! as! ActionsCell
            cell.delegate = self
            cell.key = dataSource.getKey(row: row)
            return cell
        default:
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
    func userDidUpdateLocalizationString(language: String, key: String, with value: String, message: String?) {
        dataSource.updateLocalization(language: language, key: key, with: value, message: message)
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        guard let view = obj.object as? NSView, let textMovementInt = obj.userInfo?["NSTextMovement"] as? Int, let textMovement = NSTextMovement(rawValue: textMovementInt) else {
            return
        }

        let columnIndex = tableView.column(for: view)
        let rowIndex = tableView.row(for: view)

        let newRowIndex: Int
        let newColumnIndex: Int

        switch textMovement {
        case .tab:
            if columnIndex + 1 >= tableView.numberOfColumns - 1 {
                newRowIndex = rowIndex + 1
                newColumnIndex = 1
            } else {
                newColumnIndex = columnIndex + 1
                newRowIndex = rowIndex
            }
            if newRowIndex >= tableView.numberOfRows {
                return
            }
        case .backtab:
            if columnIndex - 1 <= 0 {
                newRowIndex = rowIndex - 1
                newColumnIndex = tableView.numberOfColumns - 2
            } else {
                newColumnIndex = columnIndex - 1
                newRowIndex = rowIndex
            }
            if newRowIndex < 0 {
                return
            }
        default:
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.tableView.editColumn(newColumnIndex, row: newRowIndex, with: nil, select: true)
        }
    }
}

// MARK: - ActionsCellDelegate

extension ViewController: ActionsCellDelegate {
    func userDidRequestRemoval(of key: String) {
        dataSource.deleteLocalization(key: key)

        // reload keeping scroll position
        let rect = tableView.visibleRect
        filter()
        tableView.scrollToVisible(rect)
    }
}

// MARK: - WindowControllerToolbarDelegate

extension ViewController: WindowControllerToolbarDelegate {
    /**
     Invoked when user requests adding a new translation
     */
    func userDidRequestAddNewTranslation() {
        let addViewController = storyboard!.instantiateController(withIdentifier: "Add") as! AddViewController
        addViewController.delegate = self
        presendedAddViewController = addViewController
        presentAsSheet(addViewController)
    }

    /**
     Invoked when user requests filter change

     - Parameter filter: new filter setting
     */
    func userDidRequestFilterChange(filter: Filter) {
        guard currentFilter != filter else {
            return
        }

        currentFilter = filter
        self.filter()
    }

    /**
     Invoked when user requests searching

     - Parameter searchTerm: new search term
     */
    func userDidRequestSearch(searchTerm: String) {
        guard currentSearchTerm != searchTerm else {
            return
        }

        currentSearchTerm = searchTerm
        filter()
    }

    /**
     Invoked when user request change of the selected localization group

     - Parameter group: new localization group title
     */
    func userDidRequestLocalizationGroupChange(group: String) {
        let languages = dataSource.selectGroupAndGetLanguages(for: group)
        reloadData(with: languages, title: group)
    }

    /**
     Invoked when user requests opening a folder
     */
    func userDidRequestFolderOpen() {
        openFolder()
    }

    /**
     Invoked when user requests opening a folder for specific path
     */
    func userDidRequestFolderOpen(withPath path: String) {
        openFolder(forPath: path)
    }

    /**
     Invoked when user requests reload selected folder
     */
    func userDidRequestReloadData() {
        guard let currentOpenFolderUrl = currentOpenFolderUrl else {
            return
        }
        handleOpenFolder(currentOpenFolderUrl)

    }
}

// MARK: - AddViewControllerDelegate

extension ViewController: AddViewControllerDelegate {
    func userDidCancel() {
        dismiss()
    }

    func userDidAddTranslation(key: String, message: String?) {
        dismiss()

        dataSource.addLocalizationKey(key: key, message: message)
        filter()

        if let row = dataSource.getRowForKey(key: key) {
            DispatchQueue.main.async {
                self.tableView.scrollRowToVisible(row)
            }
        }
    }

    private func dismiss() {
        guard let presendedAddViewController = presendedAddViewController else {
            return
        }

        dismiss(presendedAddViewController)
    }
}
