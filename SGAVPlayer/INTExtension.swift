//
//  INTExtension.swift
//  SGAVPlayer
//
//  Created by BoBo on 16/11/4.
//  Copyright © 2016年 SG. All rights reserved.
//

import UIKit

extension Int
{
    // MARK: - properties
    // MARK: - methods
    /// 格式化时间显示
    func formatterSeconds() -> String
    {
        if (self <= 0)
        {
            return "00:00";
        }
        
        let hour:Int = self / 3600;
        let minute:Int = (self - 3600 * hour) / 60;
        let second:Int = self - hour * 3600 - minute * 60;
        if (hour == 0)
        {
            return String(format: "%02i:%02i", minute, second);
        }
        
        return String(format: "%02i:%02i:%02i", hour, minute, second);
    }
}
