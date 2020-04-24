/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 ViewController class.
 */

import UIKit
import AVFoundation.AVFAudio

class ViewController: UIViewController {
    
    //    @IBOutlet weak var fxSwitch: UISwitch!
    //    @IBOutlet weak var speechSwitch: UISwitch!
    @IBOutlet weak var bypassSwitch: UISwitch!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    //    @IBOutlet weak var speechMeter: LevelMeterView!
    //    @IBOutlet weak var fxMeter: LevelMeterView!
    @IBOutlet weak var voiceIOMeter: LevelMeterView!
    
    private var audioEngine: AudioEngine!
    var fileCount:Int = 0
    
    enum ButtonTitles: String {
        case record = "Record"
        case play = "Play"
        case stop = "Stop"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAudioEngine(avOption: AVAudioSession.CategoryOptions.defaultToSpeaker)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.handleInterruption(_:)),
                                               name: AVAudioSession.interruptionNotification,
                                               object: AVAudioSession.sharedInstance())
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.handleRouteChange(_:)),
                                               name: AVAudioSession.routeChangeNotification,
                                               object: AVAudioSession.sharedInstance())
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.handleMediaServicesWereReset(_:)),
                                               name: AVAudioSession.mediaServicesWereResetNotification,
                                               object: AVAudioSession.sharedInstance())
    }
    
    //    func setupAudioSession(sampleRate: Double) {
    //        let session = AVAudioSession.sharedInstance()
    //        let avOpptions:AVAudioSession.CategoryOptions = [AVAudioSession.CategoryOptions.allowBluetooth,
    //                                                         AVAudioSession.CategoryOptions.defaultToSpeaker]
    //        do {
    //            try session.setCategory(.playAndRecord, options: avOpptions)
    //        } catch {
    //            print("Could not set audio category: \(error.localizedDescription)")
    //        }
    //
    //        do {
    //            try session.setPreferredSampleRate(sampleRate)
    //        } catch {
    //            print("Could not set preferred sample rate: \(error.localizedDescription)")
    //        }
    //    }
    
    let session = AVAudioSession.sharedInstance()
    func setupAudioSession(sampleRate: Double, options :AVAudioSession.CategoryOptions) {
        
        do {
            try session.setCategory(.playAndRecord, options: options)
            try session.setPreferredSampleRate(44100)
            
        } catch {
            print("Could not set audio category: \(error.localizedDescription)")
        }
        
        do {
            try session.setPreferredSampleRate(sampleRate)
        } catch {
            print("Could not set preferred sample rate: \(error.localizedDescription)")
        }
    }
    
    func setupAudioEngine(avOption : AVAudioSession.CategoryOptions) {
        do {
            audioEngine = try AudioEngine()
            
            //speechMeter.levelProvider = audioEngine.speechPowerMeter
            //fxMeter.levelProvider = audioEngine.fxPowerMeter
            voiceIOMeter.levelProvider = audioEngine.voiceIOPowerMeter
            
            setupAudioSession(sampleRate: audioEngine.voiceIOFormat.sampleRate,
                              options: avOption)
            
            audioEngine.setup()
            audioEngine.start()
        } catch {
            fatalError("Could not set up audio engine: \(error)")
        }
    }
    
    func resetUIStates() {
        //        fxSwitch.setOn(false, animated: true)
        //        speechSwitch.setOn(false, animated: true)
        bypassSwitch.setOn(false, animated: true)
        
        recordButton.setTitle(ButtonTitles.record.rawValue, for: .normal)
        recordButton.isEnabled = true
        playButton.setTitle(ButtonTitles.play.rawValue, for: .normal)
        playButton.isEnabled = false
    }
    
    func resetAudioEngine() {
        audioEngine = nil
    }
    
    @objc
    func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        
        switch type {
        case .began:
            // Interruption began, take appropriate actions
            
            if let isRecording = audioEngine?.isRecording, isRecording {
                recordButton.setTitle(ButtonTitles.record.rawValue, for: .normal)
            }
            audioEngine?.stopRecordingAndPlayers()
            
            //            fxSwitch.setOn(false, animated: true)
            //            speechSwitch.setOn(false, animated: true)
            playButton.setTitle(ButtonTitles.record.rawValue, for: .normal)
            playButton.isEnabled = false
        case .ended:
            do {
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Could not set audio session active: \(error)")
            }
            
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    // Interruption Ended - playback should resume
                } else {
                    // Interruption Ended - playback should NOT resume
                }
            }
        @unknown default:
            fatalError("Unknown type: \(type)")
        }
    }
    
    @objc
    func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue),
            let routeDescription = userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription else { return }
        switch reason {
        case .newDeviceAvailable:
            print("newDeviceAvailable")
        case .oldDeviceUnavailable:
            print("oldDeviceUnavailable")
        case .categoryChange:
            print("categoryChange")
            print("New category: \(AVAudioSession.sharedInstance().category)")
        case .override:
            print("override")
        case .wakeFromSleep:
            print("wakeFromSleep")
        case .noSuitableRouteForCategory:
            print("noSuitableRouteForCategory")
        case .routeConfigurationChange:
            print("routeConfigurationChange")
        case .unknown:
            print("unknown")
        @unknown default:
            fatalError("Really unknown reason: \(reason)")
        }
        
        print("Previous route:\n\(routeDescription)")
        print("Current route:\n\(AVAudioSession.sharedInstance().currentRoute)")
    }
    
    @objc
    func handleMediaServicesWereReset(_ notification: Notification) {
        resetUIStates()
        resetAudioEngine()
        setupAudioEngine(avOption: AVAudioSession.CategoryOptions.defaultToSpeaker)
    }
    
    @IBAction func fxSwitchPressed(_ sender: UISwitch) {
        audioEngine?.checkEngineIsRunning()
        
        print("FX Switch pressed.")
        audioEngine?.fxPlayerPlay(sender.isOn)
    }
    
    @IBAction func speechSwitchPressed(_ sender: UISwitch) {
        audioEngine?.checkEngineIsRunning()
        
        print("Speech Switch pressed.")
        audioEngine?.speechPlayerPlay(sender.isOn)
    }
    
    @IBAction func bypassSwitchPressed(_ sender: UISwitch) {
        print("Bypass Switch pressed.")
        audioEngine?.bypassVoiceProcessing(sender.isOn)
    }
    
    @IBAction func builtInMicSwitch(_ sender: UISwitch) {
        print("builtInMicSwitch.")
        if(sender.isOn){
            setupAudioEngine(avOption: AVAudioSession.CategoryOptions.defaultToSpeaker)
        }
        else{
            setupAudioEngine(avOption: [])
        }
    }
    
    @IBAction func buetoothSwitch(_ sender: UISwitch) {
        print("buetoothSwitch.")
        if(sender.isOn){
            setupAudioEngine(avOption: AVAudioSession.CategoryOptions.allowBluetooth)
        }
        else{
            setupAudioEngine(avOption: [])
        }
    }
    
    @IBAction func wiredBuiltInSwitch(_ sender: UISwitch) {
        print("wiredBuiltInSwitch...")
        var mic : AVAudioSessionPortDescription? = nil
        
        guard let availableInputs = session.availableInputs else {
            return
        }
        
        if(sender.isOn){
            
            for input in availableInputs {
                print("input...", input.portType)
                if input.portType == .headsetMic{
                    mic = input
                }
            }
            
            do {
                try session.setPreferredInput(mic)
            }catch _ {
                print("cannot set mic ")
            }
        }
        else{
            
            for input in availableInputs {
                print("input...", input.portType)
                if input.portType == .builtInMic{
                    mic = input
                }
            }
            
            do {
                try session.setPreferredInput(mic)
            }catch _ {
                print("cannot set mic ")
            }
        }
    }
    
    //    func hasWiredHeadphones(in routeDescription: AVAudioSessionRouteDescription) -> AVAudioSessionPortDescription {
    //        // Filter the outputs to only those with a port type of wired headphones.
    //
    ////        if(!routeDescription.outputs.filter({$0.portType == .headsetMic}).isEmpty){
    ////            return routeDescription.outputs.filter({$0.portType == .headsetMic})
    ////        }
    //    }
    
    @IBAction func recordPressed(_ sender: UIButton) {
        print("Record button pressed.")
        audioEngine?.checkEngineIsRunning()
        audioEngine?.toggleRecording()
        
        if let isRecording = audioEngine?.isRecording, isRecording {
            sender.setTitle(ButtonTitles.stop.rawValue, for: .normal)
            playButton.isEnabled = false
        } else {
            sender.setTitle(ButtonTitles.record.rawValue, for: .normal)
            playButton.isEnabled = true
        }
    }
    
    @IBAction func playPressed(_ sender: UIButton) {
        print("Play button pressed.")
        audioEngine?.checkEngineIsRunning()
        audioEngine?.togglePlaying()
        
        if let isPlaying = audioEngine?.isPlaying, isPlaying {
            //            fxSwitch.setOn(false, animated: true)
            //            speechSwitch.setOn(false, animated: true)
            
            playButton.setTitle(ButtonTitles.stop.rawValue, for: .normal)
            recordButton.isEnabled = false
        } else {
            playButton.setTitle(ButtonTitles.play.rawValue, for: .normal)
            recordButton.isEnabled = true
        }
    }
    
    @IBAction func savePressed(_ sender: Any) {
        print("savePressed...")
        audioEngine?.convertToMp4(num: fileCount)
        fileCount += 1
        
        showAlert()
    }
    
    func showAlert() {
        let alert = UIAlertController(title: "Message",
                                      message: "File Saved.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
}

