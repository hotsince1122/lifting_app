import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/post_sign_in_data_decision.dart';

void main() {
  const signedInUid = 'user-b';

  final scenarios =
      <
        ({
          String name,
          String? ownerUid,
          bool hasLocalWorkouts,
          bool hasCloudBackup,
          SignInDataDecision expected,
        })
      >[
        (
          name: 'keeps data already owned by this account',
          ownerUid: signedInUid,
          hasLocalWorkouts: true,
          hasCloudBackup: true,
          expected: SignInDataDecision.continueLocal,
        ),
        (
          name: 'does not prompt for an empty database owned by this account',
          ownerUid: signedInUid,
          hasLocalWorkouts: false,
          hasCloudBackup: true,
          expected: SignInDataDecision.continueLocal,
        ),
        (
          name: 'attaches local data when there is no progress or backup',
          ownerUid: 'user-a',
          hasLocalWorkouts: false,
          hasCloudBackup: false,
          expected: SignInDataDecision.attachLocal,
        ),
        (
          name: 'offers restore when there is no local progress',
          ownerUid: 'user-a',
          hasLocalWorkouts: false,
          hasCloudBackup: true,
          expected: SignInDataDecision.offerRestore,
        ),
        (
          name: 'attaches guest workouts when there is no cloud backup',
          ownerUid: null,
          hasLocalWorkouts: true,
          hasCloudBackup: false,
          expected: SignInDataDecision.attachLocal,
        ),
        (
          name: 'asks which data to use when guest workouts and cloud coexist',
          ownerUid: null,
          hasLocalWorkouts: true,
          hasCloudBackup: true,
          expected: SignInDataDecision.chooseLocalOrCloud,
        ),
        (
          name: 'offers transfer or cloud restore for another owner',
          ownerUid: 'user-a',
          hasLocalWorkouts: true,
          hasCloudBackup: true,
          expected: SignInDataDecision.chooseTransferOrCloud,
        ),
        (
          name: 'offers transfer or sign out when another owner has no backup',
          ownerUid: 'user-a',
          hasLocalWorkouts: true,
          hasCloudBackup: false,
          expected: SignInDataDecision.chooseTransferOrSignOut,
        ),
      ];

  for (final scenario in scenarios) {
    test(scenario.name, () {
      expect(
        decideSignInData(
          signedInUid: signedInUid,
          ownerUid: scenario.ownerUid,
          hasLocalWorkouts: scenario.hasLocalWorkouts,
          hasCloudBackup: scenario.hasCloudBackup,
        ),
        scenario.expected,
      );
    });
  }
}
