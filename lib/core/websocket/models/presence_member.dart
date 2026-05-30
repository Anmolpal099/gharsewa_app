import 'package:freezed_annotation/freezed_annotation.dart';

part 'presence_member.freezed.dart';
part 'presence_member.g.dart';

/// Represents a member in a presence channel (online user)
@freezed
class PresenceMember with _$PresenceMember {
  const factory PresenceMember({
    /// The unique identifier of the user
    required String id,
    
    /// The display name of the user
    required String name,
    
    /// Optional avatar URL for the user
    String? avatar,
  }) = _PresenceMember;

  factory PresenceMember.fromJson(Map<String, dynamic> json) =>
      _$PresenceMemberFromJson(json);
}
