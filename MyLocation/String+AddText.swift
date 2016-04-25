//
//  String+AddText.swift
//  MyLocation
//
//  Created by Максим on 10.03.16.
//  Copyright © 2016 Maxim. All rights reserved.
//

import Foundation

extension String {
    mutating func addText(text: String?, withSeparator separator: String = "") {
        if let text = text {
            if !isEmpty {
                self += separator
            }
            self += text
        }
    }
}