import 'package:app/data/models/feedback_dto.dart';
import 'package:app/domain/entities/feedback.dart';

extension FeedbackDtoX on FeedbackDto {
  Feedback toEntity() => Feedback(runId, time, name);
}

extension FeedbackX on Feedback {
  FeedbackDto toDto() => FeedbackDto(runId, time, name);
}
