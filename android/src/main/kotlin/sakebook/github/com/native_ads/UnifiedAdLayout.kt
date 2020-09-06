package sakebook.github.com.native_ads

import android.content.Context
import android.view.View
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.AdListener
import com.google.android.gms.ads.AdLoader
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.LoadAdError
import com.google.android.gms.ads.MobileAds
import com.google.android.gms.ads.RequestConfiguration
import com.google.android.gms.ads.formats.MediaView
import com.google.android.gms.ads.formats.NativeAdOptions
import com.google.android.gms.ads.formats.UnifiedNativeAd
import com.google.android.gms.ads.formats.UnifiedNativeAdView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

class UnifiedAdLayout(
    context: Context,
    messenger: BinaryMessenger,
    id: Int,
    arguments: HashMap<String, Any>
) : PlatformView {

    private val hostPackageName = arguments["package_name"] as String
    private val layoutRes = context.resources.getIdentifier(arguments["layout_name"] as String, "layout", hostPackageName)
    private val unifiedNativeAdView: UnifiedNativeAdView = View.inflate(context, layoutRes, null) as UnifiedNativeAdView
    private val headlineView: TextView = unifiedNativeAdView.findViewById(context.resources.getIdentifier("headline", "id", hostPackageName))
    private val bodyView: TextView = unifiedNativeAdView.findViewById(context.resources.getIdentifier("body", "id", hostPackageName))

    private val iconView: ImageView? = unifiedNativeAdView.findViewById(context.resources.getIdentifier("icon", "id", hostPackageName))
    private val advertiserView: TextView? = unifiedNativeAdView.findViewById(context.resources.getIdentifier("advertiser", "id", hostPackageName))

    private val methodChannel: MethodChannel = MethodChannel(messenger, "com.github.sakebook.android/unified_ad_layout_$id")
    private var ad: UnifiedNativeAd? = null

    init {
        val ids = arguments["test_devices"] as MutableList<String>?
        val configuration = RequestConfiguration.Builder().setTestDeviceIds(ids).build()
        MobileAds.setRequestConfiguration(configuration)

        AdLoader.Builder(context, arguments["placement_id"] as String)
                .forUnifiedNativeAd {
                    ad = it
                    ensureUnifiedAd(it)
                }
                .withAdListener(object : AdListener() {
                    override fun onAdImpression() {
                        super.onAdImpression()
                        methodChannel.invokeMethod("onAdImpression", null)
                    }

                    override fun onAdLeftApplication() {
                        super.onAdLeftApplication()
                        methodChannel.invokeMethod("onAdLeftApplication", null)
                    }

                    override fun onAdClicked() {
                        super.onAdClicked()
                        methodChannel.invokeMethod("onAdClicked", null)
                    }

                    override fun onAdFailedToLoad(error: LoadAdError) {
                        super.onAdFailedToLoad(error)
                        methodChannel.invokeMethod("onAdFailedToLoad", hashMapOf("errorCode" to error.code))
                    }

                    override fun onAdFailedToLoad(errorCode: Int) {
                        super.onAdFailedToLoad(errorCode)
                        // TODO: Migrate deprecated method.
                        methodChannel.invokeMethod("onAdFailedToLoad", hashMapOf("errorCode" to errorCode))
                    }

                    override fun onAdLoaded() {
                        super.onAdLoaded()
                        methodChannel.invokeMethod("onAdLoaded", null)
                    }
                })
                .withNativeAdOptions(NativeAdOptions.Builder()
                        .build())
                .build()
                .loadAd(AdRequest.Builder()
                        .build())
    }

    override fun getView(): View {
        return unifiedNativeAdView
    }

    override fun dispose() {
        ad?.destroy()
        unifiedNativeAdView.removeAllViews()
        methodChannel.setMethodCallHandler(null)
    }

    private fun ensureUnifiedAd(ad: UnifiedNativeAd?) {
        headlineView.text = ad?.headline
        bodyView.text = ad?.body

        iconView?.setImageDrawable(ad?.icon?.drawable)
        advertiserView?.text = ad?.advertiser

        unifiedNativeAdView.bodyView = bodyView
        unifiedNativeAdView.headlineView = headlineView

        unifiedNativeAdView.iconView = iconView
        unifiedNativeAdView.advertiserView = advertiserView

        unifiedNativeAdView.setNativeAd(ad)
    }
}
