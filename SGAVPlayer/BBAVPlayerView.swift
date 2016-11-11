//
//  BBAVPlayerView.swift
//  BoBo
//
//  Created by alimysoyang on 16/8/30.
//  Copyright © 2016年 bobo. All rights reserved.
//

import UIKit
import AVFoundation

@objc protocol BBAVPlayerViewDelegate
{
    func bbAVPlayerViewDidPlayFailed();
    func bbAVPlayerViewDidFullScreen(isFullScreen:Bool);
}

/// 播放组件
class BBAVPlayerView: UIView 
{
    
    /// 视频播放状态
    ///
    /// - readyToPlay: 准备播放
    /// - playing:     正在播放
    /// - paused:      暂停
    /// - stopped:     停止
    /// - finished:    播放完毕
    /// - buffering:   缓冲中
    /// - failed:      播放失败
    enum BBAVPlayerState:Int
    {
        case readyToPlay = 0
        case playing
        case paused
        case stopped
        case finished
        case buffering
        case failed
    }
    
    // MARK: - properties
    weak var delegate:BBAVPlayerViewDelegate?;
    
    fileprivate var playerState:BBAVPlayerState = .finished {
        didSet {
            if (playerState == .buffering)
            {
                self.loadingView?.startAnimating();
            }
            else
            {
                self.loadingView?.stopAnimating();
            }
        }
    }
    
    var urlPath:String?;
    fileprivate let kViewTag:Int = 6500;
    fileprivate var totalDuration:Double = 0.0;
    fileprivate var currentDuration:Double = 0.0;
    fileprivate var isSliderSliding:Bool = false;
    fileprivate var isFullScreen:Bool = false;
    fileprivate var videoPlayerItem:AVPlayerItem?;
    fileprivate var videoPlayer:AVPlayer?;
    fileprivate var videoPlayerLayer:AVPlayerLayer?;
    fileprivate var timeObserver:Any?;

    fileprivate var loadingView:UIActivityIndicatorView?;

    fileprivate weak var parentView:UIView?;
    fileprivate var sourceViewFrame:CGRect = .zero;
    fileprivate var sourcePlayerLayerFrame:CGRect = .zero;
    fileprivate var sourcePlayerControlViewFrame:CGRect = .zero;
    
    fileprivate lazy var controlView:BBPlayerControlView = {
        let view:BBPlayerControlView = BBPlayerControlView(frame: CGRect(x:0.0, y:self.frame.size.height - 36.0, width:self.frame.size.width, height:36.0));
        view.alpha = 0.0;
        return view;
    }();
    
    fileprivate lazy var btnStart:UIButton = { [unowned self] in
        let button:UIButton = UIButton(frame: CGRect(x: 0.0, y:0.0, width: self.frame.size.width, height:self.frame.size.height));
        button.setImage(UIImage(named:"videoplay"), for: .normal);
        return button;
    }();
    
    // MARK: - life cycle
    init(frame: CGRect, videoUrlPath:String?) {
        super.init(frame: frame);
        self.urlPath = videoUrlPath;
        self.sourceViewFrame = frame;
        self.initViews();
    }
    
    override init(frame:CGRect)
    {
		super.init(frame:frame);
        self.sourceViewFrame = frame;
        self.initViews();
    }
	
    required init?(coder aDecoder:NSCoder)
    {
        super.init(coder:aDecoder);
    }

    deinit
    {
        self.removeAll();
        self.delegate = nil;
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event);
        if (self.isFullScreen)
        {
            self.isFullScreen = false;
            self.quitFullScreen();
            
            guard let _ = self.delegate?.bbAVPlayerViewDidFullScreen(isFullScreen: self.isFullScreen) else {
                return;
            }
        }
    }
    
    /// AVPlayerItem属性监视
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let playerItem = object as? AVPlayerItem, let key = keyPath
        {
            if (key == "status")
            {
                switch (playerItem.status)
                {
                case .unknown:
                    self.playerState = .buffering;
                    self.controlView.loadingProgress.setProgress(0.0, animated: false);
                case .readyToPlay:
                    if (self.playerState == .paused)
                    {
                        return;
                    }
                    self.readyToPlayer();
                case .failed:
                    self.playerState = .failed;
                    self.removeAll();
                    self.btnStart.alpha = 1.0;
                    self.controlView.alpha = 0.0;
                    guard let _ = self.delegate?.bbAVPlayerViewDidPlayFailed() else
                    {
                        return;
                    }
                }
            }
            else if (key == "loadedTimeRanges")
            {
                let timeInterval:Double = self.availableDuration();
                let totalDuration:Double = CMTimeGetSeconds(playerItem.duration);
                self.controlView.loadingProgress.progressTintColor = UIColor(white: 1.0, alpha: 0.7);
                self.controlView.loadingProgress.setProgress(Float(timeInterval / totalDuration), animated: false);
            }
            else if (key == "playbackBufferEmpty")//缓冲为空
            {
                self.loadingView?.startAnimating();
                if (self.videoPlayerItem!.isPlaybackBufferEmpty)
                {
                    self.playerState = .buffering;
                    
                }
            }
            else if (key == "playbackLikelyToKeepUp")//缓冲好
            {
                self.loadingView?.stopAnimating();
                if (self.videoPlayerItem!.isPlaybackLikelyToKeepUp && self.playerState == .buffering)
                {
                    self.playerState = .playing;
                }
            }
        }
    }
    
    // MARK: - public methods
    internal func startPlayer()
    {
        if let videoUrlPath:String = self.urlPath, (!videoUrlPath.trim().isEmpty)
        {
            self.initLoadingView().initPlayerItem().initPlayer().initPlayerLayer();
            NotificationCenter.default.addObserver(self, selector: #selector(BBAVPlayerView.eventVideoPlayerDidEndNotification(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.videoPlayerItem);
        }
        else
        {
            self.playerState = .failed;
            self.removeAll();
            self.btnStart.alpha = 1.0;
            self.controlView.alpha = 0.0;
            guard let _ = self.delegate?.bbAVPlayerViewDidPlayFailed() else
            {
                return;
            }
        }
        
    }
    
    internal func pause()
    {
        if (self.videoPlayer?.rate == 1.0)
        {
            self.videoPlayer?.pause();
            self.controlView.btnPlay.setImage(UIImage(named: "control_play"), for: .normal);
            self.playerState = .paused;
        }
    }
    
    internal func stopPlayer()
    {
        self.playerState = .finished;
        self.removeAll();
        self.btnStart.alpha = 1.0;
        self.controlView.alpha = 0.0;
    }
    
    // MARK: - event response
    
    /// 播放按钮控制
    internal func eventButtonClicked(_ sender:UIButton)
    {
        if (self.playerState == .failed)
        {
            guard let _ = self.delegate?.bbAVPlayerViewDidPlayFailed() else
            {
                return;
            }
        }
        else if (self.playerState == .finished)
        {
            self.startPlayer();
        }
        else
        {
            self.playOrPause(sender);
        }
    }
    
    
    /// 全屏播放按钮控制
    internal func eventFullScreenButtonClicked(_ sender:UIButton)
    {
        self.isFullScreen = !self.isFullScreen;
        if (self.isFullScreen)
        {
            self.controlView.btnFullScreen.setImage(UIImage(named:"nonfullscreen"), for: .normal);
            self.parentView = self.superview;
            self.removeFromSuperview();
            self.videoPlayerLayer?.backgroundColor = UIColor.black.cgColor;
            self.backgroundColor = UIColor.black;
            self.frame = CGRect(x: 0.0, y: 0.0, width: UIView.kScreenWidth, height: UIView.kScreenHeight);
            self.videoPlayerLayer?.frame = CGRect(x:0.0, y:0.0, width:self.frame.size.width, height:self.frame.size.height);
            self.controlView.frame = CGRect(x:0.0, y:self.frame.size.height - 36.0, width:self.frame.size.width, height:36.0);
//            switch UIDevice.current.orientation {
//            case .portrait, .portraitUpsideDown:
//                self.videoPlayerLayer?.frame = CGRect(x:0.0, y:0.0, width:self.frame.size.width, height:self.frame.size.height);
//                self.controlView.frame = CGRect(x:0.0, y:self.frame.size.height - 36.0, width:self.frame.size.width, height:36.0);
//            case .landscapeLeft:
//                self.videoPlayerLayer?.transform = CATransform3DMakeRotation((CGFloat)(M_PI_2), 0.0, 0.0, 1.0);   //CGAffineTransform(rotationAngle: (CGFloat)(M_PI_2));
//                //self.transform = CGAffineTransform(rotationAngle: (CGFloat)(M_PI_2));
//                //self.frame = CGRect(x: 0.0, y: 0.0, width: UIView.kScreenWidth, height: UIView.kScreenHeight);
//                self.videoPlayerLayer?.frame = CGRect(x:0.0, y:0.0, width:self.frame.size.height, height:self.frame.size.width);
//                self.controlView.frame = CGRect(x:0.0, y:self.frame.size.width - 36.0, width:self.frame.size.height, height:36.0);
//            case .landscapeRight:
//                self.videoPlayerLayer?.transform = CATransform3DMakeRotation(-(CGFloat)(M_PI_2), 0.0, 0.0, 1.0);
//                //self.transform = CGAffineTransform(rotationAngle: -(CGFloat)(M_PI_2));
//                //self.frame = CGRect(x: 0.0, y: 0.0, width: UIView.kScreenWidth, height: UIView.kScreenHeight);
//                self.videoPlayerLayer?.frame = CGRect(x:0.0, y:0.0, width:self.frame.size.height, height:self.frame.size.width);
//                self.controlView.frame = CGRect(x:0.0, y:self.frame.size.width - 36.0, width:self.frame.size.height, height:36.0);
//            default:
//                //self.frame = CGRect(x: 0.0, y: 0.0, width: UIView.kScreenWidth, height: UIView.kScreenHeight);
//                self.videoPlayerLayer?.frame = CGRect(x:0.0, y:0.0, width:self.frame.size.width, height:self.frame.size.height);
//                self.controlView.frame = CGRect(x:0.0, y:self.frame.size.height - 36.0, width:self.frame.size.width, height:36.0);
//            }
            self.controlView.updateViews(orientation:.portrait);
            UIApplication.shared.keyWindow?.addSubview(self);
        }
        else
        {
            self.quitFullScreen();
        }
        
        guard let _ = self.delegate?.bbAVPlayerViewDidFullScreen(isFullScreen: self.isFullScreen) else {
            return;
        }
    }
    
    
    /// 播放视频结束通知
    internal func eventVideoPlayerDidEndNotification(_ notification:Notification)
    {
        self.playerState = .stopped;
        self.videoPlayer?.seek(to: kCMTimeZero, completionHandler: { [weak self](finished:Bool) in
            if let strongSelf = self
            {
                strongSelf.videoPlayer?.play();
                strongSelf.playerState = .playing;
            }
        })
    }
    
    /// MARK: - UISlider控制回调(TouchBegan, ValueChanged, TouchEnded)
    internal func eventSliderTouchBegan(sender:UISlider)
    {
        self.isSliderSliding = true;
        self.loadingView?.startAnimating();
    }
    
    internal func eventSliderValueChanged(sender:UISlider)
    {
        self.pause();
    }
    
    internal func eventSliderTouchEnded(sender:UISlider)
    {
        self.isSliderSliding = false;

        let targetValue:Double = self.totalDuration * Double(sender.value);
        if (targetValue.isNaN)
        {
            return;
        }
        if (self.videoPlayer?.currentItem?.status == AVPlayerItemStatus.readyToPlay)
        {
            let draggedTime = CMTime(value: Int64(targetValue), timescale: 1);
            self.videoPlayer?.seek(to: draggedTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero, completionHandler: { [weak self](finished:Bool) in
                if let strongSelf = self
                {
                    strongSelf.videoPlayer?.play();
                    strongSelf.controlView.btnPlay.setImage(UIImage(named: "control_pause"), for: .normal);
                }
            })
        }
    }
    
    internal func eventDeviceOrientationChanged()
    {
        if (self.isFullScreen)
        {
            self.videoPlayerLayer?.backgroundColor = UIColor.black.cgColor;
            let orientation:UIDeviceOrientation = UIDevice.current.orientation;
            switch orientation {
            case .portrait, .portraitUpsideDown:
                self.defaultViewOrientation();
            case .landscapeLeft:
                self.videoPlayerLayer?.transform = CATransform3DMakeRotation((CGFloat)(M_PI_2), 0.0, 0.0, 1.0);
                self.videoPlayerLayer?.frame = CGRect(x:0.0, y:0.0, width:self.frame.size.width, height:self.frame.size.height);
                self.controlView.transform = CGAffineTransform(rotationAngle: (CGFloat)(M_PI_2));
                self.controlView.frame = CGRect(x:0.0, y:0.0, width:36.0, height:self.frame.size.height)
            case .landscapeRight:
                self.videoPlayerLayer?.transform = CATransform3DMakeRotation(-(CGFloat)(M_PI_2), 0.0, 0.0, 1.0);
                self.videoPlayerLayer?.frame = CGRect(x:0.0, y:0.0, width:self.frame.size.width, height:self.frame.size.height);
                self.controlView.transform = CGAffineTransform(rotationAngle: -(CGFloat)(M_PI_2));
                self.controlView.frame = CGRect(x: self.frame.size.width - 36.0, y: 0.0, width: 36.0, height: self.frame.size.height);
            default:
                self.defaultViewOrientation();
            }
            self.controlView.updateViews(orientation: orientation);
        }
    }
    
    // MARK: - private methods
    fileprivate func initViews()
    {
        self.backgroundColor = UIColor.clear;
        self.sourcePlayerControlViewFrame = self.controlView.frame;
        self.addSubview(self.btnStart);
        self.addSubview(self.controlView);
        
        self.btnStart.addTarget(self, action: #selector(BBAVPlayerView.eventButtonClicked(_:)), for: .touchUpInside);
        self.controlView.btnPlay.addTarget(self, action: #selector(BBAVPlayerView.eventButtonClicked(_:)), for: .touchUpInside);
        self.controlView.btnFullScreen.addTarget(self, action: #selector(BBAVPlayerView.eventFullScreenButtonClicked(_:)), for: .touchUpInside);
        self.controlView.progressSlider.addTarget(self, action: #selector(BBAVPlayerView.eventSliderTouchBegan(sender:)), for: .touchDown);
        self.controlView.progressSlider.addTarget(self, action: #selector(BBAVPlayerView.eventSliderValueChanged(sender:)), for: .valueChanged);
        self.controlView.progressSlider.addTarget(self, action: #selector(BBAVPlayerView.eventSliderTouchEnded(sender:)), for: [.touchUpInside, .touchCancel, .touchUpOutside]);
        NotificationCenter.default.addObserver(self, selector: #selector(BBAVPlayerView.eventDeviceOrientationChanged), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil);
    }
    
    fileprivate func loadedTimeRanges()
    {
        self.playerState = .buffering;
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
            self.playOrPause(nil);
            self.loadingView?.stopAnimating();
        });
    }
    
    
    /// 初始化加载视图
    fileprivate func initLoadingView() -> Self
    {
        if (self.loadingView == nil)
        {
            self.loadingView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge);
            self.loadingView?.frame = CGRect(x: 0.0, y: 0.0, width: self.frame.size.width, height: self.frame.size.height);
            self.addSubview(self.loadingView!);
        }
        self.btnStart.alpha = 0.0;
        self.loadingView?.startAnimating();
        return self;
    }
    
    
    /// 初始化AVPlayerItem
    fileprivate func initPlayerItem() -> Self
    {
        if let path = self.urlPath, let encodeUrlPath = path.urlQueryEncodingAllowed(), let url = URL(string: encodeUrlPath)
        {
            self.videoPlayerItem = AVPlayerItem(url: url);
            //视频状态
            self.videoPlayerItem?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil);
            //
            self.videoPlayerItem?.addObserver(self, forKeyPath: "loadedTimeRanges", options: NSKeyValueObservingOptions.new, context: nil);
            self.videoPlayerItem?.addObserver(self, forKeyPath: "playbackBufferEmpty", options: NSKeyValueObservingOptions.new, context: nil);
            self.videoPlayerItem?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: NSKeyValueObservingOptions.new, context: nil);
        }
        return self;
    }
    
    
    /// 初始化AVPlayer
    fileprivate func initPlayer() -> Self
    {
        if let _ = self.videoPlayerItem
        {
            self.videoPlayer = AVPlayer(playerItem: self.videoPlayerItem!);
        }
        return self;
    }
    
    
    /// 初始化AVPlayerLayer
    fileprivate func initPlayerLayer()
    {
        self.videoPlayerLayer = AVPlayerLayer(player:self.videoPlayer);
        self.videoPlayerLayer?.backgroundColor = UIColor.clear.cgColor;
        self.videoPlayerLayer?.videoGravity = AVLayerVideoGravityResizeAspect;
        self.videoPlayerLayer?.frame = CGRect(x:0.0, y:0.0, width:self.frame.size.width, height:self.frame.size.height);
        self.sourcePlayerLayerFrame = CGRect(x:0.0, y:0.0, width:self.frame.size.width, height:self.frame.size.height);
    }
    
    
    /// 初始化时间进度显示组件UISlider
    fileprivate func initProcessSliderTime()
    {
        let time:CMTime = CMTime(seconds: 1, preferredTimescale: 1);
        self.timeObserver = self.videoPlayer?.addPeriodicTimeObserver(forInterval: time, queue: nil, using: { [weak self](t:CMTime) in
            if let strongSelf = self
            {
                if (strongSelf.isSliderSliding)
                {
                    return;
                }
                strongSelf.syncprocessSlider();
            }
            });
        
        let playDuration:CMTime = self.playerItemDuration();
        if (CMTIME_IS_INVALID(playDuration))
        {
            self.controlView.progressSlider.value = 0.0;
        }
    }
    
    
    /// 同步显示时间进度显示组件UISlider
    fileprivate func syncprocessSlider()
    {
        let playerDuration:CMTime = self.playerItemDuration();
        if (CMTIME_IS_INVALID(playerDuration))
        {
            self.controlView.progressSlider.minimumValue = 0.0;
            return;
        }
        
        self.totalDuration = CMTimeGetSeconds(playerDuration);
        if self.totalDuration.isFinite
        {
            let minValue:Float = self.controlView.progressSlider.minimumValue;
            let maxValue:Float = self.controlView.progressSlider.maximumValue;
            self.currentDuration = CMTimeGetSeconds(self.videoPlayer!.currentTime());
            self.controlView.progressSlider.setValue((maxValue - minValue) * Float(self.currentDuration) / Float(self.totalDuration) + minValue, animated: false);
            self.controlView.lbLeftTime.text = Int(self.currentDuration).formatterSeconds(); //self.formatterSeconds(Int(self.currentDuration));
        }
        
        if (self.controlView.progressSlider.value == 1.0)
        {
            self.videoPlayer?.seek(to: kCMTimeZero);
        }
    }
    
    
    /// 开始准备播放
    fileprivate func readyToPlayer()
    {
        self.initProcessSliderTime();
        self.totalDuration = Double(self.videoPlayerItem!.duration.value) / Double(self.videoPlayerItem!.duration.timescale);
        self.controlView.lbRightTime.text = Int(self.totalDuration).formatterSeconds(); //self.formatterSeconds(Int(self.totalDuration));
        self.playerState = .readyToPlay;
        self.layer.addSublayer(self.videoPlayerLayer!);
        self.controlView.alpha = 1.0;
        self.bringSubview(toFront: self.controlView);
        self.controlView.btnPlay.setImage(UIImage(named: "control_pause"), for: .normal);
        self.videoPlayer?.play();
    }
    
    
    /// 控制播放和暂停
    fileprivate func playOrPause(_ sender:UIButton?)
    {
        if (self.videoPlayer?.rate != 1.0)
        {
            if (self.videoCurrentTime() == self.videoDuration())
            {
                self.setVideoCurrentTime(0.0);
            }
            if let button = sender
            {
                button.setImage(UIImage(named: "control_pause"), for: .normal);
            }
            self.videoPlayer?.play();
        }
        else
        {
            if let button = sender
            {
                button.setImage(UIImage(named: "control_play"), for: .normal);
            }
            self.videoPlayer?.pause();
            self.playerState = .paused;
        }
    }
    
    fileprivate func removeAll()
    {
        NotificationCenter.default.removeObserver(self);
        if let _ = self.timeObserver
        {
            self.videoPlayer?.removeTimeObserver(self.timeObserver!);
        }
        if let _ = self.videoPlayerItem
        {
            self.videoPlayerItem?.cancelPendingSeeks();
            self.videoPlayerItem?.asset.cancelLoading();
            self.videoPlayerItem?.removeObserver(self, forKeyPath: "status");
            self.videoPlayerItem?.removeObserver(self, forKeyPath: "loadedTimeRanges");
            self.videoPlayerItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty");
            self.videoPlayerItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp");
        }
        self.videoPlayer?.pause();
        self.videoPlayerLayer?.removeFromSuperlayer();
        self.videoPlayerItem = nil;
        self.videoPlayerLayer = nil;
        self.videoPlayer = nil;
        if let _ = self.loadingView
        {
            self.loadingView?.stopAnimating();
            self.loadingView?.removeFromSuperview();
            self.loadingView = nil;
        }
    }
    
    /**
     获取视频总长度
     
     - returns: 时间长度
     */
    fileprivate func videoDuration() -> Double
    {
        if let playerItem = self.videoPlayerItem , (playerItem.status == AVPlayerItemStatus.readyToPlay)
        {
            return CMTimeGetSeconds(playerItem.asset.duration);
        }
        return 0.0;
    }
    
    
    /// 获取当前已经播放的位置
    fileprivate func playerItemDuration() -> CMTime
    {
        if let playerItem = self.videoPlayerItem
        {
            if (playerItem.status == .readyToPlay)
            {
                return playerItem.duration;
            }
        }
        return kCMTimeInvalid;
    }
    
    /**
     获取视频当前播放的时间位置
     
     - returns: 当前播放时间
     */
    fileprivate func videoCurrentTime() -> Double
    {
        if let player = self.videoPlayer
        {
            return CMTimeGetSeconds(player.currentTime());
        }
        return 0.0;
    }
    
    fileprivate func setVideoCurrentTime(_ time:Double)
    {
        DispatchQueue.main.async {
            if let player = self.videoPlayer, let playerItem = self.videoPlayerItem
            {
                player.seek(to: CMTimeMakeWithSeconds(time, playerItem.currentTime().timescale));
            }
        }
    }
    
    /**
     计算缓冲进度
     
     - returns: 缓冲进度
     */
    fileprivate func availableDuration() -> Double
    {
        if let values:[NSValue] = self.videoPlayerItem?.loadedTimeRanges
        {
            if let timeRange:CMTimeRange = values.first?.timeRangeValue
            {
                let startSeconds:Double = CMTimeGetSeconds(timeRange.start);
                let durationSeconds:Double = CMTimeGetSeconds(timeRange.end);
                return startSeconds + durationSeconds;
            }
        }
        return 0.0;
    }
    
    fileprivate func defaultViewOrientation()
    {
        self.videoPlayerLayer?.transform = CATransform3DIdentity;
        self.videoPlayerLayer?.frame = CGRect(x:0.0, y:0.0, width:self.frame.size.width, height:self.frame.size.height);
        self.controlView.transform = CGAffineTransform.identity;
        self.controlView.frame = CGRect(x:0.0, y:self.frame.size.height - 36.0, width:self.frame.size.width, height:36.0);
    }
    
    fileprivate func quitFullScreen()
    {
        self.controlView.btnFullScreen.setImage(UIImage(named:"fullscreen"), for: .normal);
        self.removeFromSuperview();
        self.backgroundColor = UIColor.clear;
        self.frame = self.sourceViewFrame;
        self.videoPlayerLayer?.transform = CATransform3DIdentity;
        self.videoPlayerLayer?.frame = self.sourcePlayerLayerFrame;
        self.videoPlayerLayer?.backgroundColor = UIColor.clear.cgColor;
        self.controlView.transform = CGAffineTransform.identity;
        self.controlView.frame = self.sourcePlayerControlViewFrame;
        self.controlView.updateViews(orientation:.portrait);
        self.parentView?.addSubview(self);
    }
}

