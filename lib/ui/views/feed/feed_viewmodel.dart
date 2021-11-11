import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/locator.dart';
import '../../../models/feed.dart';
import '../../../services/auth_service.dart';
import '../../../services/feed_service.dart';
import '../../../state/app_state.dart';

class FeedViewModel extends FutureViewModel {
  final FeedService _feedService = locator<FeedService>();
  final NavigationService _navigator = locator<NavigationService>();
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();

  List<Feed> get feed => _feedService.getRxModelList();
  AppState get appState => _feedService.getAppState();
  String get userName =>
      _authenticationService.getRxModelValue().username ?? "";

  Future retrieveFeedList() async {
    await _feedService.retrieveFeedList(_authenticationService.getUser().id)
      ..when(success: (_) {
        setBusy(false);
      }, error: (error) {
        setError(error.error);
      });
  }

  void navigateToEntry(int id) {
    // _navigator.navigateTo(Routes.feedView, arguments: feed[id]);
  }

  @override
  List<ReactiveServiceMixin> get reactiveServices => [_feedService];

  @override
  Future futureToRun() => retrieveFeedList();
}
