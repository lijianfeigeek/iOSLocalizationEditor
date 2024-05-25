//
//  ActionsCell.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 05/03/2019.
//  Copyright © 2019 Igor Kulman. All rights reserved.
//

import Cocoa

// 定义 ActionsCellDelegate 协议，用于代理 ActionsCell 的删除操作
protocol ActionsCellDelegate: AnyObject {
    // 删除键值对的请求
    func userDidRequestRemoval(of key: String)
}

// ActionsCell 类，继承自 NSTableCellView，用于显示动作单元格
final class ActionsCell: NSTableCellView {
    // MARK: - Outlets

    // 删除按钮 Outlet
    @IBOutlet private weak var deleteButton: NSButton!

    // MARK: - Properties

    // 单元格标识符
    static let identifier = "ActionsCell"

    // 单元格关联的键值
    var key: String?

    // ActionsCellDelegate 代理
    weak var delegate: ActionsCellDelegate?

    // 单元格初始化完成后的操作
    override func awakeFromNib() {
        super.awakeFromNib()

        // 设置删除按钮图标和工具提示
        deleteButton.image = NSImage(named: NSImage.stopProgressTemplateName)
        deleteButton.toolTip = "delete".localized
    }

    // 删除按钮点击事件
    @IBAction private func removalClicked(_ sender: NSButton) {
        // 获取单元格关联的键值
        guard let key = key else {
            return
        }

        // 触发代理方法，删除键值对
        delegate?.userDidRequestRemoval(of: key)
    }
}

