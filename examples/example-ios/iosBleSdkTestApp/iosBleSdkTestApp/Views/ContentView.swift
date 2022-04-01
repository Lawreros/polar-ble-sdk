/// Copyright © 2021 Polar Electro Oy. All rights reserved.

import SwiftUI
import PolarBleSdk

extension Text {
    func headerStyle() -> some View {
        self
            .font(.headline)
            .foregroundColor(.secondary)
            .fontWeight(.light)
    }
}

struct ContentView: View {
    @ObservedObject var bleSdkManager: PolarBleSdkManager
    
    var body: some View {
        VStack {
            Text("PSHR_v2 BLE App")
                .bold()
            
            ScrollView(.vertical) {
                VStack(spacing: 10) {
                    if !bleSdkManager.isBluetoothOn {
                        Text("Bluetooth OFF")
                            .bold()
                            .foregroundColor(.red)
                    }
                    
                    Group {
                        Text("Connectivity:")
                            .headerStyle()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
//                        Button( bleSdkManager.isBroadcastListenOn ? "Listening broadcast" : "Listen broadcast", action: {bleSdkManager.broadcastToggle()})
//                            .buttonStyle(PrimaryButtonStyle(buttonState: getBroadcastButtonState()))
                        
                        switch bleSdkManager.deviceConnectionState {
                        case .disconnected:
                            Button("Connection Status", action: {bleSdkManager.connectToDevice()})
                                .buttonStyle(PrimaryButtonStyle(buttonState: getConnectButtonState()))
                        case .connecting(let deviceId):
                            Button("Connecting \(deviceId)", action: {})
                                .buttonStyle(PrimaryButtonStyle(buttonState: getConnectButtonState()))
                                .disabled(true)
                        case .connected(let deviceId):
                            Button("Disconnect \(deviceId)", action: {bleSdkManager.disconnectFromDevice()})
                                .buttonStyle(PrimaryButtonStyle(buttonState: getConnectButtonState()))
                        }
                        
                        Button("Auto Connect", action: { bleSdkManager.autoConnect()})
                            .buttonStyle(PrimaryButtonStyle(buttonState: getAutoConnectButtonState()))
                        
//                        Button( bleSdkManager.isSearchOn ? "Stop device scan" : "Scan devices", action: {bleSdkManager.searchToggle()})
//                            .buttonStyle(PrimaryButtonStyle(buttonState: getSearchButtonState()))
                        
                    }.disabled(!bleSdkManager.isBluetoothOn)
                    
                    Divider()
                    
                    Group {
                        Group {
                            Text("Streams:")
                                .headerStyle()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Button( bleSdkManager.isStreamOn(feature: DeviceStreamingFeature.ecg) ? "Stop ECG Stream" : "Start ECG Stream", action: {
                                streamButtonToggle(DeviceStreamingFeature.ecg) })
                                .buttonStyle(SecondaryButtonStyle(buttonState: getStreamButtonState(DeviceStreamingFeature.ecg)))
                            
//                            Button(bleSdkManager.isStreamOn(feature: DeviceStreamingFeature.acc) ? "Stop ACC Stream" : "Start ACC Stream", action: { streamButtonToggle(DeviceStreamingFeature.acc)})
//                                .buttonStyle(SecondaryButtonStyle(buttonState: getStreamButtonState(DeviceStreamingFeature.acc)))
                            
//                            Button(bleSdkManager.isStreamOn(feature: DeviceStreamingFeature.gyro) ? "Stop GYRO Stream" : "Start GYRO Stream", action: { streamButtonToggle(DeviceStreamingFeature.gyro) })
//                                .buttonStyle(SecondaryButtonStyle(buttonState: getStreamButtonState(DeviceStreamingFeature.gyro)))
                            
                            
                        }.fullScreenCover(item: $bleSdkManager.streamSettings) { streamSettings in
                            if let settings = streamSettings {
                                StreamSettingsView(bleSdkManager: bleSdkManager, streamedFeature: settings.feature, streamSettings: settings)
                            }
                        }
                        
//                        Divider()
//                        Group {
//                            Text("H10 recording:")
//                                .headerStyle()
//                                .frame(maxWidth: .infinity, alignment: .leading)
//
//                            Button(bleSdkManager.isH10RecordingEnabled ? "Stop H10 recording": "Start H10 recording", action: { bleSdkManager.h10RecordingToggle() })
//                                .buttonStyle(SecondaryButtonStyle(buttonState: getRecordingButtonState()))
//
//                            Button("Read H10 recording status", action: { bleSdkManager.getH10RecordingStatus()})
//                                .buttonStyle(SecondaryButtonStyle(buttonState: getRecordingStatusButtonState()))
//
//
//                        }
                        Divider()
                        Group{
                            Text("Recieved Data Packet")
                                .headerStyle()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("HR: \(bleSdkManager.hr_message)")
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .font(.system(size: 30))
                                .padding()
                                .foregroundColor(.none)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.black, lineWidth: 2)
                                )
                            
                            Text("ECG: \(bleSdkManager.ecg_message)")
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .font(.system(size: 30))
                                .padding()
                                .foregroundColor(.none)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.black, lineWidth: 2)
                                )
                            Text("Battery: \(bleSdkManager.battery_level)%")
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .font(.system(size: 15))
                                .padding()
                                .foregroundColor(.none)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color.black, lineWidth:2)
                                )
                        }
                    }.disabled(!bleSdkManager.isDeviceConnected)
                }.frame(maxWidth: .infinity)
            }
        }.alert(item: $bleSdkManager.generalError) { message in
            Alert(
                title: Text(message.text),
                dismissButton: .cancel()
            )
        }.alert(item: $bleSdkManager.generalMessage) { message in
            Alert(
                title: Text(message.text),
                dismissButton: .cancel()
            )
        }
    }
    
    func streamButtonToggle(_ feature:DeviceStreamingFeature) {
        NSLog("Stream toggle for feature \(feature)")
        if(bleSdkManager.isStreamOn(feature: feature)) {
            bleSdkManager.streamStop(feature: feature)
        } else {
            if(feature == DeviceStreamingFeature.ppi) {
                bleSdkManager.ppiStreamStart()
            } else {
                bleSdkManager.getStreamSettings(feature: feature)
            }
        }
    }
    
    func getConnectButtonState() -> ButtonState {
        if bleSdkManager.isBluetoothOn {
            switch bleSdkManager.deviceConnectionState {
            case .disconnected:
                return ButtonState.released
            case .connecting(_):
                return ButtonState.disabled
            case .connected(_):
                return ButtonState.pressedDown
            }
        }
        return ButtonState.disabled
    }
    
    func getBroadcastButtonState() -> ButtonState {
        if bleSdkManager.isBluetoothOn {
            if bleSdkManager.isBroadcastListenOn {
                return ButtonState.pressedDown
            } else {
                return ButtonState.released
            }
        }
        return ButtonState.disabled
    }
    
    func getAutoConnectButtonState() -> ButtonState {
        if bleSdkManager.isBluetoothOn && !bleSdkManager.isDeviceConnected {
            return ButtonState.released
        } else {
            return ButtonState.disabled
        }
    }
    
    func getSearchButtonState() -> ButtonState {
        if bleSdkManager.isBluetoothOn {
            if bleSdkManager.isSearchOn {
                return ButtonState.pressedDown
            } else {
                return ButtonState.released
            }
        }
        return ButtonState.disabled
    }
    
    func getStreamButtonState(_ feature: DeviceStreamingFeature) -> ButtonState {
        if bleSdkManager.isDeviceConnected && bleSdkManager.supportedStreamFeatures.contains(feature) {
            if bleSdkManager.isStreamOn(feature: feature) {
                return ButtonState.pressedDown
            } else {
                return ButtonState.released
            }
        }
        return ButtonState.disabled
    }
    
    func getSdkModeButtonState() -> ButtonState {
        if bleSdkManager.isDeviceConnected && bleSdkManager.isSdkFeatureSupported {
            if bleSdkManager.isSdkStreamModeEnabled {
                return ButtonState.pressedDown
            } else {
                return ButtonState.released
            }
        }
        return ButtonState.disabled
    }
    
    func getFtpButtonState() -> ButtonState {
        if bleSdkManager.isDeviceConnected && bleSdkManager.isFtpFeatureSupported {
            return ButtonState.released
        } else {
            return ButtonState.disabled
        }
    }
    
    func getRecordingButtonState() -> ButtonState {
        if bleSdkManager.isDeviceConnected && bleSdkManager.isH10RecordingSupported {
            if bleSdkManager.isH10RecordingEnabled {
                return ButtonState.pressedDown
            } else {
                return ButtonState.released
            }
        }
        return ButtonState.disabled
    }
    
    func getRecordingStatusButtonState() -> ButtonState {
        if bleSdkManager.isDeviceConnected && bleSdkManager.isH10RecordingSupported {
            return ButtonState.released
        } else {
            return ButtonState.disabled
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(["iPhone 8", "iPAD Pro (12.9-inch)"], id: \.self) { deviceName in
            ContentView(bleSdkManager: PolarBleSdkManager())
                .previewDevice(PreviewDevice(rawValue: deviceName))
                .previewDisplayName(deviceName)
        }
        
    }
}
