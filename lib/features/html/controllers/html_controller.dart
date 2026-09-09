import 'package:get/get.dart';
import 'package:sixam_mart/util/html_type.dart';
import 'package:sixam_mart/features/html/domain/services/html_service_interface.dart';

class HtmlController extends GetxController implements GetxService {
  final HtmlServiceInterface htmlServiceInterface;
  HtmlController({required this.htmlServiceInterface});

  String? _htmlText;
  String? get htmlText => _htmlText;

  String? _pageTitle;
  String? get pageTitle => _pageTitle;

  String? _pageImage;
  String? get pageImage => _pageImage;

  Future<void> getHtmlText(HtmlType htmlType) async {
    _htmlText = null;
    Response response = await htmlServiceInterface.getHtmlText(htmlType);
    if (response.statusCode == 200) {
      if(response.body is Map && response.body['page_description'] != null){
        final bool pageStatus = response.body['page_status'] == 1 || response.body['page_status'] == true;
        _htmlText = pageStatus ? response.body['page_description'].toString() : '';
        if(pageStatus) {
          _pageTitle = response.body['page_title']?.toString();
          _pageImage = response.body['page_image_full_url']?.toString();
        }
      }else if(response.body != null && response.body.isNotEmpty && response.body is String){
        _htmlText = response.body;
      }else{
        _htmlText = '';
      }
      if(_htmlText != null && _htmlText!.isNotEmpty) {
        _htmlText = _htmlText!.replaceAll('href=', 'target="_blank" href=');
      }else {
        _htmlText = '';
      }
    }
    update();
  }

  void resetHtmlText() {
    _htmlText = null;
    _pageTitle = null;
    _pageImage = null;
  }

}