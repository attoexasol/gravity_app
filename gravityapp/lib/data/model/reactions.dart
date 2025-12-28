/// Reactions model for posts
/// Represents user reactions (heart, thumbs up, fire) on a post
class Reactions {
  late final int heart;
  late final int thumbsUp;
  late final int fire;

  Reactions({required this.heart, required this.thumbsUp, required this.fire});

  Reactions copyWith({int? heart, int? thumbsUp, int? fire}) {
    return Reactions(
      heart: heart ?? this.heart,
      thumbsUp: thumbsUp ?? this.thumbsUp,
      fire: fire ?? this.fire,
    );
  }
}

