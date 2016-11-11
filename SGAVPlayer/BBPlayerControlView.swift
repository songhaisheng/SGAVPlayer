//
//  BBPlayerControlView.swift
//  BoBo
//
//  Created by alimysoyang on 16/10/8.
//  Copyright © 2016年 bobo. All rights reserved.
//

import UIKit

//播放组件控制器
class BBPlayerControlView: UIView 
{
    // MARK: - properties
    lazy var btnPlay:UIButton = {
        let button:UIButton = UIButton(frame: CGRect(x: 5.0, y: 0.0, width: 36.0, height: 36.0));
        button.setImage(UIImage(named:"control_play"), for: .normal);
        return button;
    }();
    
    lazy var progressSlider:UISlider = {
        let slider:UISlider = UISlider(frame: CGRect(x: 91.0, y: 0.0, width: self.frame.size.width - 172.0, height: 36.0));
        slider.minimumValue = 0.0;
        slider.value = 0.0;
        slider.setThumbImage(UIImage(named:"control_dot"), for: .normal);
        slider.minimumTrackTintColor = UIColor.green;
        slider.maximumTrackTintColor = UIColor.clear;
        
        return slider;
    }();
    
    lazy var loadingProgress:UIProgressView = {
        let progressView:UIProgressView = UIProgressView(progressViewStyle: UIProgressViewStyle.default);
        progressView.frame = CGRect(x: 93.0, y: 17.0, width: self.frame.size.width - 176.0, height: 1.0);
        progressView.progressTintColor = UIColor.clear;
        progressView.trackTintColor = UIColor.lightGray;
        return progressView;
    }();
    
    lazy var btnFullScreen:UIButton = {
        let button:UIButton = UIButton(frame: CGRect(x: self.frame.size.width - 36.0, y: 0.0, width: 36.0, height: 36.0));
        button.setImage(UIImage(named:"fullscreen"), for: .normal);
        return button;
    }();
    
    lazy var lbLeftTime:UILabel = {
        let label:UILabel = UILabel(frame: CGRect(x: 46.0, y: 0.0, width: 40.0, height: 36.0));
        label.textColor = UIColor.white;
        label.font = BBHelper.p12;
        label.text = "00:00";
        return label;
    }();
    
    lazy var lbRightTime:UILabel = {
        let label:UILabel = UILabel(frame: CGRect(x: self.frame.size.width - 81.0, y: 0.0, width: 40.0, height: 36.0));
        label.textColor = UIColor.white;
        label.font = BBHelper.p12;
        label.text = "00:00";
        return label;
    }();
    
    fileprivate var isShowFullScreen:Bool = true;
    
    // MARK: - life cycle
    init(frame: CGRect, showFullScreen:Bool = true) {
        super.init(frame: frame);
        self.isShowFullScreen = showFullScreen;
        self.initViews();
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
    }
    
    // MARK: - private methods
    fileprivate func initViews()
    {
        self.addSubview(self.btnPlay);
        self.addSubview(self.lbLeftTime);
        self.addSubview(self.loadingProgress);
        self.addSubview(self.progressSlider);
        self.addSubview(self.lbRightTime);
        if (self.isShowFullScreen)
        {
            self.addSubview(self.btnFullScreen);
        }
        else
        {
            self.progressSlider.frame = CGRect(x: 91.0, y: 0.0, width: self.frame.size.width - 136.0, height: 36.0);
            self.loadingProgress.frame = CGRect(x: 93.0, y: 17.0, width: self.frame.size.width - 140.0, height: 1.0);
            self.lbRightTime.frame = CGRect(x: self.frame.size.width - 45.0, y: 0.0, width: 40.0, height: 36.0)
        }
    }
    
    // MARK: - public methods
    internal func updateViews(orientation: UIDeviceOrientation)
    {
        if (orientation == .landscapeLeft)
        {
            self.btnPlay.frame = CGRect(x: 5.0, y: 0.0, width: 36.0, height: 36.0);
            self.lbLeftTime.frame = CGRect(x: 46.0, y: 0.0, width: 40.0, height: 36.0);
            self.progressSlider.frame = CGRect(x: 91.0, y: 0.0, width: self.frame.size.height - 172.0, height: 36.0);
            self.loadingProgress.frame = CGRect(x: 93.0, y: 17.0, width: self.frame.size.height - 176.0, height: 1.0);
            self.lbRightTime.frame = CGRect(x: self.frame.size.height - 81.0, y: 0.0, width: 40.0, height: 36.0);
            self.btnFullScreen.frame = CGRect(x: self.frame.size.height - 36.0, y: 0.0, width: 36.0, height: 36.0);
        }
        else if (orientation == .landscapeRight)
        {
            self.btnPlay.frame = CGRect(x: 5.0, y: 0.0, width: 36.0, height: 36.0);
            self.lbLeftTime.frame = CGRect(x: 46.0, y: 0.0, width: 40.0, height: 36.0);
            self.progressSlider.frame = CGRect(x: 91.0, y: 0.0, width: self.frame.size.height - 172.0, height: 36.0);
            self.loadingProgress.frame = CGRect(x: 93.0, y: 17.0, width: self.frame.size.height - 176.0, height: 1.0);
            self.lbRightTime.frame = CGRect(x: self.frame.size.height - 81.0, y: 0.0, width: 40.0, height: 36.0);
            self.btnFullScreen.frame = CGRect(x: self.frame.size.height - 36.0, y: 0.0, width: 36.0, height: 36.0);
        }
        else
        {
            self.btnPlay.frame = CGRect(x: 5.0, y: 0.0, width: 36.0, height: 36.0);
            self.lbLeftTime.frame = CGRect(x: 46.0, y: 0.0, width: 40.0, height: 36.0);
            self.progressSlider.frame = CGRect(x: 91.0, y: 0.0, width: self.frame.size.width - 172.0, height: 36.0);
            self.loadingProgress.frame = CGRect(x: 93.0, y: 17.0, width: self.frame.size.width - 176.0, height: 1.0);
            self.lbRightTime.frame = CGRect(x: self.frame.size.width - 81.0, y: 0.0, width: 40.0, height: 36.0);
            self.btnFullScreen.frame = CGRect(x: self.frame.size.width - 36.0, y: 0.0, width: 36.0, height: 36.0);
        }
    }
}
