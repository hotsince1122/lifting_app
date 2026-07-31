import 'dart:math';

enum WeeklyProgressMessageType {
  notStarted,
  firstWorkoutDone,
  oneRemaining,
  inProgress,
  completed,
}

String selectProgressMessage({
  required int currentProgress,
  required int target,
  required DateTime weekStart,
}) {
  final int remaining = currentProgress < target ? target - currentProgress : 0;

  final WeeklyProgressMessageType messageType;

  if (currentProgress >= target) {
    messageType = WeeklyProgressMessageType.completed;
  } else if (remaining == 1) {
    messageType = WeeklyProgressMessageType.oneRemaining;
  } else if (currentProgress == 0) {
    messageType = WeeklyProgressMessageType.notStarted;
  } else if (currentProgress == 1) {
    messageType = WeeklyProgressMessageType.firstWorkoutDone;
  } else {
    messageType = WeeklyProgressMessageType.inProgress;
  }

  final messages = weeklyProgressMessages[messageType]!;

  final weekSeed =
      weekStart.year * 10000 + weekStart.month * 100 + weekStart.day;

  final seed = weekSeed * 1000 + currentProgress * 10 + target;

  final random = Random(seed);
  final randomIndex = random.nextInt(messages.length);
  final selectedMessage = messages[randomIndex];

  return selectedMessage.replaceAll('{remaining}', remaining.toString());
}

const Map<WeeklyProgressMessageType, List<String>> weeklyProgressMessages = {
  WeeklyProgressMessageType.notStarted: [
    'Your first workout starts here.',
    'Ready when you are.',
    'One workout gets things moving.',
    'Start with one solid session.',
    'Your weekly goal starts with one.',
    'Time to get the first workout in.',
    'The first workout is waiting.',
    'Let’s put the first one on the board.',
  ],
  WeeklyProgressMessageType.firstWorkoutDone: [
    'One workout down, {remaining} to go.',
    'First workout done. Keep it going.',
    'Good start. {remaining} workouts left.',
    'One on the board, {remaining} remaining.',
    'The first one’s done. Keep moving.',
    'You’re underway. {remaining} to go.',
    'Solid start. {remaining} workouts left.',
    'That’s one done. {remaining} left.',
  ],
  WeeklyProgressMessageType.oneRemaining: [
    'One more workout to reach your goal.',
    'Just one workout left this week.',
    'One more and your weekly goal is done.',
    'Your goal is one workout away.',
    'Only one workout to go.',
    'One session left to complete your goal.',
    'You’re one workout from your goal.',
    'Just one more and you’re there.',
  ],
  WeeklyProgressMessageType.inProgress: [
    '{remaining} workouts left to reach your goal.',
    '{remaining} more workouts to go.',
    'Keep going. {remaining} workouts left.',
    'Good progress. {remaining} to go.',
    '{remaining} workouts left this week.',
    'You’re on your way. {remaining} more to go.',
    'Another one done. {remaining} remaining.',
    'Stay with it. {remaining} workouts left.',
    'Your goal is {remaining} workouts away.',
    '{remaining} sessions left to reach your goal.',
    'Progress made. {remaining} workouts to go.',
    'Keep the rhythm. {remaining} workouts left.',
    'You’ve got {remaining} workouts left.',
    '{remaining} workouts left. Keep moving.',
    'The goal is closer. {remaining} to go.',
    'Keep building. {remaining} workouts to go.',
  ],
  WeeklyProgressMessageType.completed: [
    'Weekly goal complete.',
    'You reached your weekly goal.',
    'Goal done. Nice work this week.',
    'That’s your weekly goal done.',
    'Weekly target reached.',
    'You got it done this week.',
    'Goal complete. Keep it going.',
    'This week’s goal is complete.',
  ],
};
