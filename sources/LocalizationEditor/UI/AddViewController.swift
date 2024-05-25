//
//  AddViewController.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 14/03/2019.
//  Copyright © 2019 Igor Kulman. All rights reserved.
//

import Cocoa   // 导入 Cocoa 框架

// 定义 AddViewControllerDelegate 协议，提供用户点击 “取消” 和 “添加翻译” 时的回调
protocol AddViewControllerDelegate: AnyObject {
    func userDidCancel()
    func userDidAddTranslation(key: String, message: String?)
}

// AddViewController 类，NSViewController 的子类，用于添加翻译
final class AddViewController: NSViewController {

    // MARK: - Outlets

    // 关联 IBOutlet，用于获取输入的 key 和 message
    @IBOutlet private weak var keyTextField: NSTextField!
    @IBOutlet private weak var addButton: NSButton!
    @IBOutlet private weak var messageTextField: NSTextField!

    // MARK: - Properties

    // 弱引用 AddViewControllerDelegate 协议的 delegate，用于回调
    weak var delegate: AddViewControllerDelegate?

    // 视图加载时调用 setup() 函数，设置代理和其他属性
    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    // MARK: - Setup

    // 设置代理，为 textField 设置 delegate
    private func setup() {
        keyTextField.delegate = self
    }

    // MARK: - Actions

    // 点击 “取消” 按钮时，调用 delegate 的 userDidCancel() 函数
    @IBAction private func cancelAction(_ sender: Any) {
        delegate?.userDidCancel()
    }

    // 点击 “添加” 按钮时，调用 delegate 的 userDidAddTranslation(_:message:) 函数
    @IBAction private func addAction(_ sender: Any) {
        // 判断 keyTextField 的字符串是否为空，不为空则调用 delegate 的 userDidAddTranslation(_:message:) 函数
        guard !keyTextField.stringValue.isEmpty else {
            return
        }

        // 调用 delegate 的 userDidAddTranslation(_:message:) 函数，message 可为 nil
        delegate?.userDidAddTranslation(key: keyTextField.stringValue, message: messageTextField.stringValue.isEmpty ? nil : messageTextField.stringValue)
    }
}

// MARK: - NSTextFieldDelegate

// AddViewController 遵循 NSTextFieldDelegate 协议，为 textField 实现文本改变时的回调
extension AddViewController: NSTextFieldDelegate {
    // 文本改变时，动态设置 addButton 的 enabled 状态
    func controlTextDidChange(_ obj: Notification) {
        addButton.isEnabled = !keyTextField.stringValue.isEmpty
    }
}
