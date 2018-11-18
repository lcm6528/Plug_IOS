//
//  ClassHeader.swift
//  Plug
//
//  Created by changmin lee on 04/11/2018.
//  Copyright © 2018 changmin. All rights reserved.
//

import Foundation
import UIKit

class ClassHeader: UIView {
    
    @IBOutlet weak var label: UILabel!
    func configure(type: UserType, count: Int) {
        label.text = type == .teacher ? "관리중인 클래스(\(count))" : "가입한 클래스\(count)"
    }
}