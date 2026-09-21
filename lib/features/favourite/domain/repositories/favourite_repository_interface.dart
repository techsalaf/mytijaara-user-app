import 'package:sixam_mart/interfaces/repository_interface.dart';

abstract class FavouriteRepositoryInterface<ResponseModel> implements RepositoryInterface<ResponseModel> {
  @override
  Future<ResponseModel> add(dynamic a, {bool isStore = false, int? id, bool isServiceModule = false});
  @override
  Future<ResponseModel> delete(int? id, {bool isStore = false, bool isServiceModule = false});
}