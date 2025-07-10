//
//  SGCustomVC.swift
//  CustomVideoPlayer
//
//  Created by Santhakumar on 10/07/25.
//

import UIKit
import AVFoundation // its required for audio / video playback
import AVKit        // its required for AVPictureInPicture Controller - PIP Player


class SGCustomVC: UIViewController {
    
    // MARK: - UI Components
    private let containerView: UIView = .init()
    private let overlayView: UIView = .init()
    
    
    //Progressbar based video duration playing
    private let progressView: UIProgressView = .init(progressViewStyle: .default)
    
    //Pip and play nd pause button
    private let pipButton: UIButton = .init(type: .system)
    private let playPauseButton: UIButton = .init(type: .system)
 
    
    //Images for playand pause button
    private let playImage: UIImage? = UIImage(systemName: "play.fill")
    private let pauseImage: UIImage? = UIImage(systemName: "pause.fill")
    
    
    
    // MARK: - AVPlayer Components
    private var player: AVPlayer!
    private var playerLayer: AVPlayerLayer!
    private var pipController: AVPictureInPictureController?
    
    private var timeObserverToken: Any?
    private var hasEnded: Bool = false
    
    // Constraint to maintain the aspect ratio of the video
    private var aspectRatioConstraint: NSLayoutConstraint?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupAudioSession()
        setupUI()
        loadVideo()
        
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Ensure Player's Layer matches the Container Size when Layout changes
        playerLayer?.frame = containerView.bounds
    }
    
    
    // MARK: - setupUI components
    func setupUI() {
        containerView.backgroundColor = .white.withAlphaComponent(0.7)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        view.backgroundColor = .black
        
        
        let containerViewTapGesture: UITapGestureRecognizer = .init(target: self, action: #selector(overlayTap))
        containerView.addGestureRecognizer(containerViewTapGesture)
        
        
        
        overlayView.backgroundColor = .black.withAlphaComponent(0.4)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(overlayView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 300)
        ])
        
        
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: containerView.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        
        //playpause button
        
        playPauseButton.setImage(playImage, for: .normal)
        playPauseButton.backgroundColor = .black.withAlphaComponent(0.6)
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.layer.cornerRadius = 25
        playPauseButton.addTarget(self, action: #selector(playPauseToggle), for: .touchUpInside)
        
        overlayView.addSubview(playPauseButton)
        
        NSLayoutConstraint.activate([
            playPauseButton.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            playPauseButton.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor),
            playPauseButton.heightAnchor.constraint(equalToConstant: 50),
            playPauseButton.widthAnchor.constraint(equalToConstant: 50)
        ])
        
        
         progressView.progress = 0
         progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.tintColor = .white
         progressView.backgroundColor = .black.withAlphaComponent(0.6)
         overlayView.addSubview(progressView)
        progressView.progress = 0.2
        
        
        NSLayoutConstraint.activate([
            progressView.leadingAnchor.constraint(equalTo: overlayView.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: overlayView.trailingAnchor),
            progressView.bottomAnchor.constraint(equalTo: overlayView.bottomAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 10)
        ])
        
        
        pipButton.setImage(UIImage(named: "pip"), for: .normal)
        pipButton.translatesAutoresizingMaskIntoConstraints = false
        pipButton.tintColor = .white
        pipButton.addTarget(self, action: #selector(pipToggle), for: .touchUpInside)
        view.addSubview(pipButton)

        
        NSLayoutConstraint.activate([
            pipButton.topAnchor.constraint(equalTo: containerView.bottomAnchor),
            pipButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            pipButton.heightAnchor.constraint(equalToConstant: 50),
            pipButton.widthAnchor.constraint(equalToConstant: 50)
        ])
        
    }
    
    
}

//MARK: - AV Methods
extension SGCustomVC {
    
    func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AVAudioSession error - \(error)")
        }
    }
    
    // Load & Prepare the Video
    func loadVideo() {
        // Sample Video URL
        guard let url = URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4") else { return }
        
        let asset = AVURLAsset(url: url)
        
        
        Task {
            do {
                let _ = try await asset.load(.tracks)
                
                DispatchQueue.main.async {
                    
                    let item = AVPlayerItem(asset: asset)
                    self.player = AVPlayer(playerItem: item)
                    
                    self.playerLayer = AVPlayerLayer(player: self.player)
                    
                    self.containerView.layer.insertSublayer(self.playerLayer, at: 0)
                    self.playerLayer.frame = self.containerView.bounds
                    
                
                }
                
            } catch {
                print("Failed to load video -", error)
            }
        }
        
        
    }
    
    
    
}




//MARK: - Objc Methods
extension SGCustomVC {
    @objc func playPauseToggle() {
        print("playPauseToggle")
        
        guard let player else {
            return
        }

        if hasEnded {
            player.seek(to: .zero) { _ in
                self.hasEnded = false
                self.playPauseButton.setImage(self.playImage, for: .normal)
            }
        } else if player.timeControlStatus == .playing {
            player.pause()
            self.playPauseButton.setImage(self.playImage, for: .normal)
        } else {
            if player.currentTime() == .zero {
                overlayView.isHidden = true
            }
            player.play()
            self.playPauseButton.setImage(self.pauseImage, for: .normal)
        }
    }
    
    @objc func pipToggle() {
        
    }
    
    @objc func overlayTap() {
        overlayView.isHidden.toggle()
    }
}



import SwiftUI

struct SGCustomVCWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> SGCustomVC {
        return SGCustomVC()
    }

    func updateUIViewController(_ uiViewController: SGCustomVC, context: Context) {
        // Optional: Handle SwiftUI state updates here
    }
}

#Preview {
    SGCustomVCWrapper()
}
