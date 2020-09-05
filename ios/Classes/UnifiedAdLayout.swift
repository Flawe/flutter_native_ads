//
//  UnifiedAdLayout.swift
//  native_ads
//
//  Created by ShinyaSakemoto on 2019/08/23.
//

import Foundation
import GoogleMobileAds

class UnifiedAdLayout : NSObject, FlutterPlatformView {
    
    private let channel: FlutterMethodChannel
    private let messenger: FlutterBinaryMessenger
    private let frame: CGRect
    private let viewId: Int64
    private let args: [String: Any]
    private let adLoader: GADAdLoader
    
    private let placementId: String
    private let layoutName: String
    private let attributionText: String

    private let nativeAdView: GADUnifiedNativeAdView!
    
    private weak var iconView: UIImageView?
    private weak var starRatingView: UILabel?
    private weak var storeView: UILabel?
    private weak var priceView: UILabel?
    
    init(frame: CGRect, viewId: Int64, args: [String: Any], messenger: FlutterBinaryMessenger) {
        self.args = args
        self.messenger = messenger 
        self.frame = frame
        self.viewId = viewId
        self.placementId = self.args["placement_id"] as! String
        self.layoutName = self.args["layout_name"] as! String
        self.attributionText = self.args["text_attribution"] as! String

        if var testDevs = self.args["test_devices"] as? [String] {
            if let simId = kGADSimulatorID as? String {
                testDevs.append(simId)
                GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = testDevs
            }
        }

        self.adLoader = GADAdLoader(adUnitID: placementId, rootViewController: nil, adTypes: [ .unifiedNative ], options: nil)
        channel = FlutterMethodChannel(name: "com.github.sakebook.ios/unified_ad_layout_\(viewId)", binaryMessenger: messenger)
        
        guard let nibObjects = Bundle.main.loadNibNamed(layoutName, owner: nil, options: nil),
              let adView = nibObjects.first as? GADUnifiedNativeAdView else {
            fatalError("Could not load nib file for adView")
        }
        nativeAdView = adView

        super.init()
        fetchAd()
    }

    private func fetchAd() {
        adLoader.delegate = self
        let request = GADRequest()
        adLoader.load(request)
    }
    
    func view() -> UIView {
        return nativeAdView 
    }
    
    fileprivate func dispose() {
        nativeAdView.nativeAd = nil
        channel.setMethodCallHandler(nil)
    }
}

extension UnifiedAdLayout : GADUnifiedNativeAdLoaderDelegate {
    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: GADRequestError) {
        channel.invokeMethod("didFailToReceiveAdWithError", arguments: ["errorCode": error.code, "message": error.localizedDescription])
    }
    
    public func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADUnifiedNativeAd) {
        channel.invokeMethod("didReceive", arguments: nil)

        // show images/videos
        nativeAdView.mediaView?.mediaContent = nativeAd.mediaContent
        
        // headline is always present
        (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline

        // advertiser
        (nativeAdView.advertiserView as? UILabel)?.text = nativeAd.advertiser
        nativeAdView.advertiserView?.isHidden = nativeAd.advertiser == nil

        // body
        (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body
        nativeAdView.bodyView?.isHidden = nativeAd.body == nil

        // call to action
        (nativeAdView.callToActionView as? UILabel)?.text = nativeAd.callToAction
        nativeAdView.callToActionView?.isHidden = nativeAd.callToAction == nil

        // In order for the SDK to process touch events properly, user interaction
        // should be disabled.
        nativeAdView.callToActionView?.isUserInteractionEnabled = false

        // Associate the native ad view with the native ad object. This is
        // required to make the ad clickable.
        // Note: this should always be done after populating the ad views.
        nativeAdView.nativeAd = nativeAd
        

        //iconView?.image = nativeAd.icon?.image
        //starRatingView?.text = String(describing: nativeAd.starRating?.doubleValue)
        //storeView?.text = nativeAd.store
        //priceView?.text = nativeAd.price
        
        // Set ourselves as the native ad delegate to be notified of native ad events.
        nativeAd.delegate = self
    }
}

// MARK: - GADUnifiedNativeAdDelegate implementation
extension UnifiedAdLayout : GADUnifiedNativeAdDelegate {
    
    func nativeAdDidRecordClick(_ nativeAd: GADUnifiedNativeAd) {
        channel.invokeMethod("nativeAdDidRecordClick", arguments: nil)
    }
    
    func nativeAdDidRecordImpression(_ nativeAd: GADUnifiedNativeAd) {
        channel.invokeMethod("nativeAdDidRecordImpression", arguments: nil)
    }
    
    func nativeAdWillLeaveApplication(_ nativeAd: GADUnifiedNativeAd) {
        channel.invokeMethod("nativeAdWillLeaveApplication", arguments: nil)
    }
}
