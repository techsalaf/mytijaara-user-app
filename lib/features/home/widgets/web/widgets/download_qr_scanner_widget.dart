import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:url_launcher/url_launcher_string.dart';

class DownloadQrScannerWidget extends StatelessWidget {
  const DownloadQrScannerWidget({super.key, this.googlePlayUrl, this.appStoreUrl, this.title,
    this.qrData, this.onClose});

  final String? googlePlayUrl;
  final String? appStoreUrl;
  final String? title;
  final String? qrData;
  final VoidCallback? onClose;


  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(width: 240, constraints: const BoxConstraints(minHeight: 240),
        margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF262626), borderRadius: BorderRadius.circular(10),
        image: const DecorationImage(image: AssetImage(Images.qrScannerBg), fit: BoxFit.cover)),
        child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
          Positioned(top: -8, right: -8,
            child: InkWell(
              onTap: onClose ?? Get.back,
              child: Container(height: 24, width: 24,
                decoration: const BoxDecoration(color: Color(0xFF4A4A4A), shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
          Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
            Transform.translate(offset: const Offset(0,  -4),
              child: Container(width: 100, height: 100,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: ClipRRect(borderRadius: BorderRadius.circular(8),
                  child: Container(color: Colors.white, alignment: Alignment.center,
                    child: qrData!.isNotEmpty ? QrImageView(
                      data: qrData ?? '', version: QrVersions.auto, backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                    ) : Text('QR', style: robotoBold.copyWith(fontSize:  28, color: const Color(0xFF262626))),
                  ),
                ),
              ),
            ),

            const SizedBox(height: Dimensions.paddingSizeSmall),

            Text(title ?? '',
              textAlign: TextAlign.center,
              style: robotoMedium.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall),
            ),

            const SizedBox(height: Dimensions.paddingSizeDefault),

            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Expanded(child: _StoreButton(
                onTap: () => _launchUrl(googlePlayUrl ?? ''),
                icon: Image.asset(Images.playStoreLogo, height: 16, fit: BoxFit.contain),
                title: 'google_play'.tr,
              )),
              const SizedBox(width: 14),
              Expanded(child: _StoreButton(
                onTap: () => _launchUrl(appStoreUrl ?? ''),
                icon: Image.asset(Images.appleSoreLogo, height: 16, fit: BoxFit.contain),
                title: 'app_store'.tr,
              )),
            ]),
          ]),
        ]),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {if(await canLaunchUrlString(url)) {await launchUrlString(url);}}
}

class _StoreButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget icon;
  final String title;

  const _StoreButton({required this.onTap, required this.icon, required this.title});

  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
        child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          icon,
          const SizedBox(width: 2),
          Flexible(child: Text(title, overflow: TextOverflow.ellipsis, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall - 3))),
        ]),
      ),
    );
}
