import 'dart:ui';

import 'package:flame/geometry.dart';
import 'package:flame/components.dart';

import '/game/enemy.dart';
import '/game/friend.dart';
import '/game/dino_run.dart';
import '/game/audio_manager.dart';
import '/models/player_data.dart';

/// This enum represents the animation states of [Dino].
enum DinoAnimationStates {
  idle,
  run,
  kick,
  hit,
  sprint,
}

// This represents the dino character of this game.
class Dino extends SpriteAnimationGroupComponent<DinoAnimationStates>
    with HasHitboxes, Collidable, HasGameRef<DinoRun> {
  // A map of all the animation states and their corresponding animations.
  static final _animationMap = {
    DinoAnimationStates.idle: SpriteAnimationData.sequenced(
      amount: 4,
      stepTime: 0.1,
      textureSize: Vector2.all(24),
    ),
    DinoAnimationStates.run: SpriteAnimationData.sequenced(
      amount: 6,
      stepTime: 0.1,
      textureSize: Vector2.all(24),
      texturePosition: Vector2((4) * 24, 0),
    ),
    DinoAnimationStates.kick: SpriteAnimationData.sequenced(
      amount: 4,
      stepTime: 0.1,
      textureSize: Vector2.all(24),
      texturePosition: Vector2((4 + 6) * 24, 0),
    ),
    DinoAnimationStates.hit: SpriteAnimationData.sequenced(
      amount: 3,
      stepTime: 0.1,
      textureSize: Vector2.all(24),
      texturePosition: Vector2((4 + 6 + 4) * 24, 0),
    ),
    DinoAnimationStates.sprint: SpriteAnimationData.sequenced(
      amount: 7,
      stepTime: 0.1,
      textureSize: Vector2.all(24),
      texturePosition: Vector2((4 + 6 + 4 + 3) * 24, 0),
    ),
  };

  // The max distance from top of the screen beyond which
  // dino should never go. Basically the screen height - ground height
  double yMax = 0.0;

  // Dino's current speed along y-axis.
  double speedY = 0.0;

  // Controlls how long the hit animations will be played.
  final Timer _hitTimer = Timer(1);

  static const double gravity = 800;

  final PlayerData playerData;

  bool isHit = false;

  Dino(Image image, this.playerData)
      : super.fromFrameData(image, _animationMap);

  @override
  void onMount() {
    // First reset all the important properties, because onMount()
    // will be called even while restarting the game.
    _reset();

    // Add a hitbox for dino.
    final shape = HitboxRectangle(relation: Vector2(0.5, 0.7));
    addHitbox(shape);
    yMax = y;

    /// Set the callback for [_hitTimer].
    _hitTimer.onTick = () {
      current = DinoAnimationStates.run;
      isHit = false;
    };

    super.onMount();
  }

  @override
  void update(double dt) {
    // v = u + at
    speedY += gravity * dt;

    // d = s0 + s * t
    y += speedY * dt;

    /// This code makes sure that dino never goes beyond [yMax].
    if (isOnGround) {
      y = yMax;
      speedY = 0.0;
      if ((current != DinoAnimationStates.hit) &&
          (current != DinoAnimationStates.run)) {
        current = DinoAnimationStates.run;
      }
    }

    _hitTimer.update(dt);
    super.update(dt);
  }

  // Gets called when dino collides with other Collidables.
  @override
  void onCollision(Set<Vector2> intersectionPoints, Collidable other) {
    // Call hit only if other component is an Enemy and dino
    // is not already in hit state.
    if ((other is Enemy) && (!isHit)) {
      badHit();
    }
    if ((other is Friend) && (!isHit)) {
      goodHit();
    }
    super.onCollision(intersectionPoints, other);
  }

  // Returns true if dino is on ground.
  bool get isOnGround => (y >= yMax);

  // Makes the dino jump.
  void jump() {
    // Jump only if dino is on ground.
    if (isOnGround) {
      speedY = -300;
      current = DinoAnimationStates.idle;
      AudioManager.instance.playSfx('jump14.wav');
    }
  }

  // This method changes the animation state to
  /// [DinoAnimationStates.hit], plays the hit sound
  /// effect and reduces the player life by 1.
  void badHit() {
    isHit = true;
    AudioManager.instance.playSfx('hurt7.wav');
    current = DinoAnimationStates.hit;
    _hitTimer.start();
    playerData.lives -= 1;
  }

  void goodHit() {
    isHit = true;
    AudioManager.instance.playSfx('hurt7.wav');
    current = DinoAnimationStates.hit;
    _hitTimer.start();
    playerData.lives += 1;
  }

  // This method reset some of the important properties
  // of this component back to normal.
  void _reset() {
    shouldRemove = false;
    anchor = Anchor.bottomLeft;
    position = Vector2(32, gameRef.size.y - 22);
    size = Vector2.all(24);
    current = DinoAnimationStates.run;
    isHit = false;
    speedY = 0.0;
  }
}
