//
//  StringExtension.swift
//  SGAVPlayer
//
//  Created by BoBo on 16/11/4.
//  Copyright © 2016年 SG. All rights reserved.
//

import UIKit

extension String {
    
    func trim() -> String
    {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
    }
    
    func urlQueryEncodingAllowed() -> String?
    {
        return self.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed);
    }
}
