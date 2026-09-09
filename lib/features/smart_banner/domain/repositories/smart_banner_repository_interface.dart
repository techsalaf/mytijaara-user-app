import 'package:sixam_mart/interfaces/repository_interface.dart';

abstract class SmartBannerRepositoryInterface implements RepositoryInterface {
  @override
  Future getList({int? offset});
}
