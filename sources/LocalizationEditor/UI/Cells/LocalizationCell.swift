//
//  LocalizationCell.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//

// 注释：导入Cocoa框架
import Cocoa

// 注释：定义一个协议LocalizationCellDelegate，继承AnyObject，并声明两个必须实现的方法
protocol LocalizationCellDelegate: AnyObject {
    // 注释：当文本控件结束编辑时触发
    func controlTextDidEndEditing(_ obj: Notification)
    
    // 注释：当用户更新区域化字符串时触发，参数分别为语言、键、值和可选的消息
    func userDidUpdateLocalizationString(language: String, key: String, with value: String, message: String?)
}

// 最终类 LocalizationCell 是 NSTableCellView 的子类
final class LocalizationCell: NSTableCellView {
    
    // MARK: - Outlets

    // @IBOutlet 属性包装器用于将 Interface Builder 中的视图连接到代码中
    // valueTextField 是 NSTextField 类的实例，它显示本地化字符串的值
    @IBOutlet private weak var valueTextField: NSTextField!

    // MARK: - Properties

    // 类属性 identifier 用于标识本地化单元格的唯一标识符
    static let identifier = "LocalizationCell"

    // delegate 属性是 LocalizationCellDelegate 协议的可选实例，用于处理单元格相关的事件
    weak var delegate: LocalizationCellDelegate?

    // language 属性是一个可选的字符串，用于存储所选语言
    var language: String?

    // value 属性是 LocalizationString? 类型，用于存储本地化字符串
    // didSet 属性观察器在 value 属性发生变化时，会调用 setStateUI() 方法更新 UI 界面
    var value: LocalizationString? {
        didSet {
            valueTextField.stringValue = value?.value ?? ""
            valueTextField.delegate = self
            setStateUI()
        }
    }

    // setStateUI() 方法用于更新界面，根据 valueTextField 的字符串是否为空，设置 layer 的边框颜色
    private func setStateUI() {
        valueTextField.layer?.borderColor = valueTextField.stringValue.isEmpty ? NSColor.red.cgColor : NSColor.clear.cgColor
    }

    // awakeFromNib() 方法是 NSTableCellView 的生命周期方法，在加载 NIB 文件时调用
    // 在该方法中，设置 valueTextField 的 wantsLayer 属性为 true，并设置 layer 的边框宽度、圆角半径
    override func awakeFromNib() {
        super.awakeFromNib()

        valueTextField.wantsLayer = true
        valueTextField.layer?.borderWidth = 1.0
        valueTextField.layer?.cornerRadius = 0.0
    }

    // focus() 方法用于激活 NSTextField，并将选中范围设置为空，将光标移动到文档末尾
    func focus() {
        valueTextField?.becomeFirstResponder()
        valueTextField?.currentEditor()?.selectedRange = NSRange(location: 0, length: 0)
        valueTextField?.currentEditor()?.moveToEndOfDocument(nil)
    }
}

// MARK: - Delegate

// 扩展 LocalizationCell，遵循 NSTextFieldDelegate 协议
extension LocalizationCell: NSTextFieldDelegate {
    
    // controlTextDidEndEditing(_:) 方法，当文本控件编辑结束时调用
    func controlTextDidEndEditing(_ obj: Notification) {
        
        // 调用代理对象的 controlTextDidEndEditing(_:) 方法
        delegate?.controlTextDidEndEditing(obj)
        
        // 解包 language 和 value
        guard let language = language, let value = value else {
            return
        }
        
        // 调用 setStateUI() 方法
        setStateUI()
        
        // 调用代理方法，传递相关参数
        delegate?.userDidUpdateLocalizationString(language: language, key: value.key, with: valueTextField.stringValue, message: value.message)
    }
}
