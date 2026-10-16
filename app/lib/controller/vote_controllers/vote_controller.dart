import 'package:get/get.dart';

import '../../model/vote.dart';
import '../../service/api_service.dart';

class VoteController extends GetxController {
  final _api = ApiService.instance;

  final poll = Rxn<VotePoll>();
  final isLoading = false.obs;
  final hasVoted = false.obs;
  final myOptionId = Rxn<int>();
  final error = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    loadCurrentPoll();
  }

  Future<void> loadCurrentPoll() async {
    isLoading.value = true;
    error.value = null;
    try {
      poll.value = await _api.getCurrentPoll();
    } catch (e) {
      error.value = 'Oylama yüklenemedi';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> castVote(int optionId) async {
    final p = poll.value;
    if (p == null) return;
    isLoading.value = true;
    error.value = null;
    try {
      poll.value = await _api.castVote(p.id, optionId);
      myOptionId.value = optionId;
      hasVoted.value = true;
    } catch (e) {
      error.value = 'Oy verilemedi';
    } finally {
      isLoading.value = false;
    }
  }
}
