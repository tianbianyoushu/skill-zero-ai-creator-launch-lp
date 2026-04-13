import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Level Data (tile coordinates) ──────────────────────────────────────────
// World: 100 tiles wide × 9 tiles tall
// Ground occupies y=7 (2 tiles thick)

// Ground segments [startX, endX] (exclusive end)
const _groundSegs = [
  (0, 21),
  (23, 37),
  (39, 57),
  (59, 74),
  (76, 100),
];

// Platforms: (x, y, width) in tiles
const _platDef = [
  (5, 5, 3),
  (10, 4, 4),
  (15, 5, 3),
  (19, 3, 3),
  (25, 5, 3),
  (30, 4, 4),
  (35, 6, 3),
  (41, 5, 3),
  (47, 4, 5),
  (55, 5, 3),
  (61, 5, 4),
  (67, 4, 3),
  (71, 5, 3),
  (78, 4, 4),
  (85, 5, 3),
  (91, 3, 5),
];

// Pipes: (x, heightInTiles) placed on ground
const _pipeDef = [
  (21, 2),
  (37, 3),
  (57, 2),
  (74, 3),
];

// Coins: (x, y) tile positions
const _coinDef = [
  (6, 4), (7, 4), (8, 4),
  (11, 3), (12, 3), (13, 3),
  (16, 4), (17, 4),
  (20, 2), (21, 2),
  (26, 4), (27, 4),
  (31, 3), (32, 3), (33, 3),
  (36, 5), (37, 5),
  (42, 4), (43, 4), (44, 4),
  (48, 3), (49, 3), (50, 3), (51, 3),
  (56, 4), (57, 4),
  (62, 4), (63, 4), (64, 4),
  (68, 3), (69, 3),
  (72, 4), (73, 4),
  (79, 3), (80, 3), (81, 3),
  (86, 4), (87, 4),
  (92, 2), (93, 2), (94, 2), (95, 2),
];

// Enemy start positions (tile x), placed on ground
const _enemyDef = [9, 13, 19, 28, 34, 37, 43, 50, 56, 64, 69, 73, 81, 87, 93];

const _kGroundY = 7.0; // tile y of ground surface
const _kLevelW = 100.0;
const _kGoalX = 97.0;

// ─── Physics Constants ────────────────────────────────────────────────────────

const _kGravity = 28.0; // tiles/s²
const _kJump = -13.5; // tiles/s
const _kSpeed = 7.5; // tiles/s
const _kESpeed = 2.2; // tiles/s

// ─── Entities ─────────────────────────────────────────────────────────────────

class _Player {
  double x, y;
  double vx = 0, vy = 0;
  bool onGround = false;
  bool facingRight = true;
  int animFrame = 0;
  double animTimer = 0;
  bool isDead = false;
  double deadTimer = 0;
  int score = 0;
  int coins = 0;
  int lives = 3;

  _Player(this.x, this.y);

  // Hitbox (slightly smaller than 1 tile)
  double get l => x + 0.08;
  double get r => x + 0.72;
  double get t => y;
  double get b => y + 1.35;
  Rect get rect => Rect.fromLTRB(l, t, r, b);
}

class _Enemy {
  double x, y, vx;
  bool alive = true;
  bool onGround = false;
  double deathTimer = 0;

  _Enemy(this.x, this.y, {this.vx = -_kESpeed});

  double get l => x + 0.05;
  double get r => x + 0.95;
  double get t => y + 0.05;
  double get b => y + 0.85;
  Rect get rect => Rect.fromLTRB(l, t, r, b);
}

class _Coin {
  double x, y;
  bool collected = false;
  double popTimer = 0;

  _Coin(this.x, this.y);

  Rect get rect => Rect.fromLTWH(x + 0.2, y + 0.1, 0.6, 0.8);
}

// ─── Game State ───────────────────────────────────────────────────────────────

enum _Phase { playing, dying, won, gameOver }

class _GameState {
  late _Player player;
  late List<_Enemy> enemies;
  late List<_Coin> coins;
  late List<Rect> solids; // tile-coordinate solid rects

  _Phase phase = _Phase.playing;
  double cameraX = 0; // tile units
  double phaseTimer = 0;

  _GameState() {
    _init();
  }

  void _init() {
    player = _Player(2.0, _kGroundY - 1.35);
    enemies = _enemyDef
        .map((tx) => _Enemy(tx.toDouble(), _kGroundY - 0.9))
        .toList();
    coins = _coinDef.map((c) => _Coin(c.$1.toDouble(), c.$2.toDouble())).toList();
    phase = _Phase.playing;
    cameraX = 0;
    phaseTimer = 0;
    _buildSolids();
  }

  void _buildSolids() {
    solids = [];
    for (final g in _groundSegs) {
      solids.add(Rect.fromLTWH(
          g.$1.toDouble(), _kGroundY, (g.$2 - g.$1).toDouble(), 2.0));
    }
    for (final p in _platDef) {
      solids.add(Rect.fromLTWH(p.$1.toDouble(), p.$2.toDouble(), p.$3.toDouble(), 1.0));
    }
    for (final p in _pipeDef) {
      final pipeY = _kGroundY - p.$2;
      solids.add(Rect.fromLTWH(p.$1.toDouble(), pipeY, 2.0, p.$2.toDouble() + 2.0));
    }
  }

  void reset() => _init();

  void triggerJump() {
    if (phase != _Phase.playing) return;
    if (player.onGround) {
      player.vy = _kJump;
      player.onGround = false;
    }
  }

  void update(double dt, bool left, bool right) {
    if (phase == _Phase.gameOver || phase == _Phase.won) return;

    if (phase == _Phase.dying) {
      phaseTimer += dt;
      player.vy += _kGravity * dt;
      player.y += player.vy * dt;
      if (phaseTimer > 2.5) {
        player.lives--;
        if (player.lives <= 0) {
          phase = _Phase.gameOver;
        } else {
          phase = _Phase.playing;
          final respawnX = math.max(0.0, cameraX);
          player = _Player(respawnX + 1.0, _kGroundY - 1.35);
        }
      }
      return;
    }

    _updatePlayer(dt, left, right);

    for (final e in enemies) {
      if (!e.alive) {
        e.deathTimer += dt;
        continue;
      }
      _updateEnemy(e, dt);
    }

    for (final c in coins) {
      if (c.collected) c.popTimer += dt;
    }

    // Camera: keep player ~40% from left
    final targetCam = player.x - 4.0;
    cameraX = targetCam.clamp(0.0, _kLevelW - 14.0);

    if (player.x >= _kGoalX) {
      phase = _Phase.won;
      phaseTimer = 0;
    }
  }

  void _updatePlayer(double dt, bool left, bool right) {
    // Horizontal
    if (left && !right) {
      player.vx = -_kSpeed;
      player.facingRight = false;
    } else if (right && !left) {
      player.vx = _kSpeed;
      player.facingRight = true;
    } else {
      player.vx = 0;
    }
    if (player.x < 0 && player.vx < 0) player.vx = 0;

    // Gravity
    player.vy += _kGravity * dt;

    // Move Y first
    final prevY = player.y;
    player.y += player.vy * dt;
    player.onGround = false;

    for (final s in solids) {
      final pr = player.rect;
      if (!pr.overlaps(s)) continue;
      if (player.vy >= 0 && prevY + 1.35 <= s.top + 0.05) {
        // Landing on top
        player.y = s.top - 1.35;
        player.vy = 0;
        player.onGround = true;
      } else if (player.vy < 0 && prevY >= s.bottom - 0.05) {
        // Hitting ceiling
        player.y = s.bottom;
        player.vy = 0;
      }
    }

    // Move X
    final prevX = player.x;
    player.x += player.vx * dt;

    for (final s in solids) {
      final pr = player.rect;
      if (!pr.overlaps(s)) continue;
      if (player.vx > 0 && prevX + 0.72 <= s.left + 0.05) {
        player.x = s.left - 0.72;
        player.vx = 0;
      } else if (player.vx < 0 && prevX + 0.08 >= s.right - 0.05) {
        player.x = s.right - 0.08;
        player.vx = 0;
      }
    }

    // Fall into pit
    if (player.y > 11) {
      _die();
      return;
    }

    // Coins
    final pr = player.rect;
    for (final c in coins) {
      if (!c.collected && pr.overlaps(c.rect)) {
        c.collected = true;
        player.coins++;
        player.score += 100;
      }
    }

    // Enemies
    for (final e in enemies) {
      if (!e.alive) continue;
      if (!pr.overlaps(e.rect)) continue;
      final prevBottom = prevY + 1.35;
      if (player.vy > 0 && prevBottom < e.rect.center.dy) {
        // Stomp
        e.alive = false;
        e.deathTimer = 0;
        player.vy = _kJump * 0.55;
        player.score += 200;
      } else {
        _die();
        return;
      }
    }

    // Animation
    if (player.onGround && player.vx.abs() > 0.5) {
      player.animTimer += dt;
      if (player.animTimer > 0.13) {
        player.animTimer = 0;
        player.animFrame = 1 - player.animFrame;
      }
    } else if (player.onGround) {
      player.animFrame = 0;
      player.animTimer = 0;
    }
  }

  void _updateEnemy(_Enemy e, double dt) {
    e.vy += _kGravity * dt;

    final prevEY = e.y;
    e.y += e.vy * dt;
    e.onGround = false;

    for (final s in solids) {
      if (!e.rect.overlaps(s)) continue;
      if (e.vy >= 0 && prevEY + 0.9 <= s.top + 0.05) {
        e.y = s.top - 0.9;
        e.vy = 0;
        e.onGround = true;
      } else if (e.vy < 0 && prevEY >= s.bottom - 0.05) {
        e.y = s.bottom;
        e.vy = 0;
      }
    }

    final prevEX = e.x;
    e.x += e.vx * dt;

    for (final s in solids) {
      if (!e.rect.overlaps(s)) continue;
      if (e.vx > 0 && prevEX + 0.95 <= s.left + 0.05) {
        e.x = s.left - 0.95;
        e.vx = -e.vx;
      } else if (e.vx < 0 && prevEX + 0.05 >= s.right - 0.05) {
        e.x = s.right - 0.05;
        e.vx = -e.vx;
      }
    }

    // Turn at ledge edges
    if (e.onGround) {
      final checkX = e.vx > 0 ? e.x + 1.05 : e.x - 0.1;
      final ledgeCheck = Rect.fromLTWH(checkX, _kGroundY, 0.05, 0.1);
      final hasFloor = solids.any((s) => s.overlaps(ledgeCheck));
      if (!hasFloor) e.vx = -e.vx;
    }

    if (e.y > 11) e.alive = false;
  }

  void _die() {
    phase = _Phase.dying;
    phaseTimer = 0;
    player.isDead = true;
    player.vy = _kJump * 1.1;
    player.vx = 0;
  }
}

// ─── Painter ─────────────────────────────────────────────────────────────────

class _GamePainter extends CustomPainter {
  final _GameState state;
  final double animTime;

  _GamePainter(this.state, this.animTime);

  @override
  bool shouldRepaint(_GamePainter old) => true;

  @override
  void paint(Canvas canvas, Size size) {
    final ts = size.height / 9.0; // tile size in px
    final cam = state.cameraX;

    _drawSky(canvas, size, ts, cam);
    _drawClouds(canvas, size, ts, cam);

    canvas.save();
    canvas.translate(-cam * ts, 0);

    _drawGround(canvas, ts);
    _drawPlatforms(canvas, ts);
    _drawPipes(canvas, ts);
    _drawCoins(canvas, ts);
    _drawGoal(canvas, ts);
    _drawEnemies(canvas, ts);
    _drawPlayer(canvas, ts, state.player);

    canvas.restore();
  }

  void _drawSky(Canvas canvas, Size size, double ts, double cam) {
    final p = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF4488FF), Color(0xFF88CCFF)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), p);
  }

  void _drawClouds(Canvas canvas, Size size, double ts, double cam) {
    final p = Paint()..color = Colors.white.withOpacity(0.9);
    final clouds = [
      (3.0, 1.3), (9.0, 0.8), (16.0, 1.6), (23.0, 0.9),
      (31.0, 1.4), (39.0, 0.7), (47.0, 1.8), (55.0, 1.1),
      (63.0, 1.5), (71.0, 0.8), (80.0, 1.3), (89.0, 1.7),
    ];
    for (final (cx, cy) in clouds) {
      // Parallax at 0.4x speed
      final sx = (cx - cam * 0.4) * ts;
      final sy = cy * ts;
      _cloud(canvas, sx, sy, ts, p);
    }
  }

  void _cloud(Canvas canvas, double sx, double sy, double ts, Paint p) {
    canvas.drawOval(Rect.fromCenter(
        center: Offset(sx, sy), width: ts * 2.8, height: ts * 0.9), p);
    canvas.drawOval(Rect.fromCenter(
        center: Offset(sx - ts * 0.7, sy + ts * 0.25), width: ts * 1.6, height: ts * 0.8), p);
    canvas.drawOval(Rect.fromCenter(
        center: Offset(sx + ts * 0.8, sy + ts * 0.2), width: ts * 2.0, height: ts * 0.75), p);
  }

  void _drawGround(Canvas canvas, double ts) {
    final grass = Paint()..color = const Color(0xFF58A024);
    final dirt = Paint()..color = const Color(0xFF9C6514);
    final darkGrass = Paint()..color = const Color(0xFF3E7A18);

    for (final g in _groundSegs) {
      final x = g.$1 * ts;
      final y = _kGroundY * ts;
      final w = (g.$2 - g.$1) * ts;

      // Dirt fill
      canvas.drawRect(Rect.fromLTWH(x, y + ts * 0.25, w, ts * 2), dirt);
      // Grass strip
      canvas.drawRect(Rect.fromLTWH(x, y, w, ts * 0.28), grass);
      // Grass tufts
      for (double gx = x + ts * 0.15; gx < x + w - ts * 0.1; gx += ts * 0.55) {
        canvas.drawRect(Rect.fromLTWH(gx, y, ts * 0.22, ts * 0.28), darkGrass);
      }
    }
  }

  void _drawPlatforms(Canvas canvas, double ts) {
    final brick = Paint()..color = const Color(0xFFCC5500);
    final brickDark = Paint()..color = const Color(0xFF993300);
    final brickLight = Paint()..color = const Color(0xFFFF8840);

    for (final pd in _platDef) {
      final x = pd.$1 * ts;
      final y = pd.$2 * ts;
      final w = pd.$3 * ts;

      canvas.drawRect(Rect.fromLTWH(x, y, w, ts), brick);
      // Top highlight
      canvas.drawRect(Rect.fromLTWH(x, y, w, ts * 0.12), brickLight);
      // Bottom shadow
      canvas.drawRect(Rect.fromLTWH(x, y + ts * 0.88, w, ts * 0.12), brickDark);
      // Mortar lines (horizontal)
      canvas.drawRect(Rect.fromLTWH(x, y + ts * 0.48, w, ts * 0.08), brickDark);
      // Mortar (vertical, alternating)
      final bw = ts * 0.95;
      for (double bx = x; bx < x + w; bx += bw) {
        canvas.drawRect(Rect.fromLTWH(bx + bw - ts * 0.04, y, ts * 0.06, ts * 0.5), brickDark);
      }
      for (double bx = x + bw * 0.5; bx < x + w; bx += bw) {
        canvas.drawRect(Rect.fromLTWH(bx - ts * 0.02, y + ts * 0.5, ts * 0.06, ts * 0.5), brickDark);
      }
    }
  }

  void _drawPipes(Canvas canvas, double ts) {
    final pipeBody = Paint()..color = const Color(0xFF148A14);
    final pipeLite = Paint()..color = const Color(0xFF28C828);
    final pipeDark = Paint()..color = const Color(0xFF0A5C0A);

    for (final pd in _pipeDef) {
      final px = pd.$1 * ts;
      final pipeH = pd.$2;
      final pipeY = (_kGroundY - pipeH) * ts;
      final capH = ts * 0.35;
      final bodyW = ts * 1.7;
      final capW = ts * 2.0;
      final bodyX = px + (capW - bodyW) / 2;

      // Pipe body
      canvas.drawRect(Rect.fromLTWH(bodyX, pipeY + capH, bodyW, pipeH * ts - capH), pipeBody);
      canvas.drawRect(Rect.fromLTWH(bodyX + bodyW * 0.15, pipeY + capH, bodyW * 0.15, pipeH * ts - capH), pipeLite);
      canvas.drawRect(Rect.fromLTWH(bodyX + bodyW * 0.8, pipeY + capH, bodyW * 0.12, pipeH * ts - capH), pipeDark);

      // Cap
      canvas.drawRect(Rect.fromLTWH(px, pipeY, capW, capH), pipeBody);
      canvas.drawRect(Rect.fromLTWH(px + capW * 0.12, pipeY, capW * 0.15, capH), pipeLite);
      canvas.drawRect(Rect.fromLTWH(px + capW * 0.8, pipeY, capW * 0.12, capH), pipeDark);
    }
  }

  void _drawCoins(Canvas canvas, double ts) {
    final gold = Paint()..color = const Color(0xFFFFCC00);
    final goldDark = Paint()..color = const Color(0xFFCC9900);
    final goldShine = Paint()..color = const Color(0xFFFFEE66);

    for (final c in state.coins) {
      if (c.collected) {
        // Pop animation
        if (c.popTimer < 0.4) {
          final progress = c.popTimer / 0.4;
          final alpha = (1.0 - progress).clamp(0.0, 1.0);
          final popY = c.y - progress * 1.5;
          final cx = (c.x + 0.5) * ts;
          final cy = popY * ts;
          final r = ts * 0.28 * (1.0 - progress * 0.3);
          canvas.drawCircle(Offset(cx, cy), r, Paint()..color = Color.fromARGB((alpha * 255).toInt(), 255, 204, 0));
        }
        continue;
      }

      // Spinning coin
      final phase = (animTime * 3 + c.x * 0.5) % (math.pi * 2);
      final scaleX = math.cos(phase).abs();
      final cx = (c.x + 0.5) * ts;
      final cy = (c.y + 0.45) * ts;
      final rW = ts * 0.28 * scaleX;
      final rH = ts * 0.38;

      if (rW > 1) {
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: rW * 2, height: rH * 2), gold);
        canvas.drawOval(Rect.fromCenter(center: Offset(cx - rW * 0.2, cy), width: rW * 0.6, height: rH * 1.6), goldShine);
      } else {
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: ts * 0.1, height: rH * 2), goldDark);
      }
    }
  }

  void _drawGoal(Canvas canvas, double ts) {
    final flagPole = Paint()..color = const Color(0xFF888888);
    final flagRed = Paint()..color = const Color(0xFFFF2222);
    final px = _kGoalX * ts;

    // Pole
    canvas.drawRect(Rect.fromLTWH(px, ts * 1.0, ts * 0.15, ts * 7.0), flagPole);

    // Waving flag
    final wave = math.sin(animTime * 3) * ts * 0.15;
    final path = Path();
    path.moveTo(px + ts * 0.15, ts * 1.0);
    path.lineTo(px + ts * 1.8 + wave, ts * 1.5);
    path.lineTo(px + ts * 1.8 + wave, ts * 2.5);
    path.lineTo(px + ts * 0.15, ts * 3.0);
    path.close();
    canvas.drawPath(path, flagRed);

    // Base block
    final baseP = Paint()..color = const Color(0xFF555555);
    canvas.drawRect(Rect.fromLTWH(px - ts * 0.3, ts * 7.8, ts * 0.75, ts * 0.5), baseP);
  }

  void _drawEnemies(Canvas canvas, double ts) {
    for (final e in state.enemies) {
      if (!e.alive) {
        if (e.deathTimer < 0.4) {
          // Squished
          final prog = e.deathTimer / 0.4;
          _drawGoomba(canvas, ts, e.x, e.y, squished: true, alpha: 1 - prog);
        }
        continue;
      }
      final walkFrame = ((animTime * 4 + e.x) % 1.0) > 0.5 ? 1 : 0;
      _drawGoomba(canvas, ts, e.x, e.y,
          walkFrame: walkFrame, facingRight: e.vx > 0);
    }
  }

  void _drawGoomba(Canvas canvas, double ts, double ex, double ey,
      {int walkFrame = 0, bool facingRight = false, bool squished = false, double alpha = 1.0}) {
    final p = Paint()..style = PaintingStyle.fill;

    void r(double rx, double ry, double rw, double rh, Color c) {
      p.color = c.withOpacity(alpha);
      canvas.drawRect(Rect.fromLTWH(ex * ts + rx * ts, ey * ts + ry * ts, rw * ts, rh * ts), p);
    }

    void oval(double rx, double ry, double rw, double rh, Color c) {
      p.color = c.withOpacity(alpha);
      canvas.drawOval(
          Rect.fromLTWH(ex * ts + rx * ts, ey * ts + ry * ts, rw * ts, rh * ts), p);
    }

    if (squished) {
      // Squished goomba
      oval(0.05, 0.5, 0.9, 0.35, const Color(0xFFAA5500));
      r(0.1, 0.6, 0.35, 0.18, Colors.white);
      r(0.55, 0.6, 0.35, 0.18, Colors.white);
      return;
    }

    // Body (mushroom shape)
    oval(0.05, 0.2, 0.9, 0.75, const Color(0xFFAA5500));
    // Feet
    if (walkFrame == 0) {
      oval(0.0, 0.75, 0.38, 0.22, const Color(0xFF884400));
      oval(0.52, 0.68, 0.38, 0.22, const Color(0xFF884400));
    } else {
      oval(0.0, 0.68, 0.38, 0.22, const Color(0xFF884400));
      oval(0.52, 0.75, 0.38, 0.22, const Color(0xFF884400));
    }
    // Eyes
    final double eyeDir = facingRight ? 0.5 : 0.0;
    r(0.12 + eyeDir * 0.02, 0.28, 0.3, 0.25, Colors.white);
    r(0.55 + eyeDir * 0.02, 0.28, 0.3, 0.25, Colors.white);
    r(0.18 + eyeDir * 0.06, 0.32, 0.18, 0.18, Colors.black);
    r(0.61 + eyeDir * 0.06, 0.32, 0.18, 0.18, Colors.black);
    // Angry brows
    r(0.10, 0.22, 0.34, 0.09, const Color(0xFF331100));
    r(0.54, 0.22, 0.34, 0.09, const Color(0xFF331100));
    // Fangs
    r(0.18, 0.68, 0.14, 0.12, Colors.white);
    r(0.60, 0.68, 0.14, 0.12, Colors.white);
  }

  void _drawPlayer(Canvas canvas, double ts, _Player pl) {
    canvas.save();
    canvas.translate(pl.x * ts, pl.y * ts);

    if (!pl.facingRight) {
      canvas.translate(ts * 0.8, 0);
      canvas.scale(-1.0, 1.0);
    }

    final p = Paint()..style = PaintingStyle.fill;
    final double w = ts * 0.8;
    final double h = ts * 1.35;

    void r(double rx, double ry, double rw, double rh, Color c) {
      p.color = c;
      canvas.drawRect(Rect.fromLTWH(rx * w, ry * h, rw * w, rh * h), p);
    }

    void oval(double rx, double ry, double rw, double rh, Color c) {
      p.color = c;
      canvas.drawOval(Rect.fromLTWH(rx * w, ry * h, rw * w, rh * h), p);
    }

    void roundRect(double rx, double ry, double rw, double rh, double rad, Color c) {
      p.color = c;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(rx * w, ry * h, rw * w, rh * h),
            Radius.circular(rad)),
        p,
      );
    }

    final bool walking = pl.onGround && pl.vx.abs() > 0.5;
    final int fr = pl.animFrame;

    // === HEAD ===
    // Curly black hair (rounded top)
    roundRect(0.1, 0.0, 0.8, 0.28, w * 0.35, const Color(0xFF1A1A2E));
    // Extra hair volume (curly bumps)
    oval(-0.02, 0.02, 0.28, 0.20, const Color(0xFF1A1A2E));
    oval(0.74, 0.02, 0.28, 0.20, const Color(0xFF1A1A2E));
    oval(0.22, -0.01, 0.26, 0.16, const Color(0xFF1A1A2E));
    oval(0.52, -0.01, 0.26, 0.16, const Color(0xFF1A1A2E));

    // Face (skin)
    r(0.12, 0.18, 0.76, 0.20, const Color(0xFFD4946C));
    // Ear
    oval(-0.04, 0.22, 0.14, 0.12, const Color(0xFFD4946C));

    // Glasses frame (black outline)
    r(0.12, 0.20, 0.35, 0.17, const Color(0xFF222222));
    r(0.53, 0.20, 0.35, 0.17, const Color(0xFF222222));
    // Bridge
    r(0.45, 0.24, 0.10, 0.05, const Color(0xFF222222));
    // Lens (yellow tinted)
    r(0.15, 0.21, 0.29, 0.14, const Color(0xFFFFEE88));
    r(0.56, 0.21, 0.29, 0.14, const Color(0xFFFFEE88));
    // Pupil (looking forward)
    r(0.20, 0.24, 0.10, 0.08, const Color(0xFF4444AA));
    r(0.61, 0.24, 0.10, 0.08, const Color(0xFF4444AA));

    // Mask (white, lower face)
    roundRect(0.08, 0.31, 0.84, 0.14, w * 0.08, Colors.white);
    r(0.10, 0.33, 0.80, 0.10, const Color(0xFFEEEEEE));
    // Mask lines
    r(0.10, 0.36, 0.80, 0.02, const Color(0xFFCCCCCC));
    r(0.10, 0.40, 0.80, 0.02, const Color(0xFFCCCCCC));

    // === BODY (yellow sweater) ===
    r(0.10, 0.44, 0.80, 0.33, const Color(0xFFF5E6A0));
    // Collar
    r(0.22, 0.44, 0.56, 0.08, const Color(0xFFE8D880));
    // Sweater texture (subtle horizontal lines)
    r(0.10, 0.52, 0.80, 0.02, const Color(0xFFE8D880));
    r(0.10, 0.60, 0.80, 0.02, const Color(0xFFE8D880));
    r(0.10, 0.68, 0.80, 0.02, const Color(0xFFE8D880));
    // Arms (skin tone peeking at wrist)
    r(-0.05, 0.46, 0.16, 0.28, const Color(0xFFF5E6A0));
    r(0.89, 0.46, 0.16, 0.28, const Color(0xFFF5E6A0));
    r(-0.05, 0.64, 0.16, 0.10, const Color(0xFFD4946C));
    r(0.89, 0.64, 0.16, 0.10, const Color(0xFFD4946C));

    // === PANTS (brown) ===
    r(0.10, 0.76, 0.80, 0.24, const Color(0xFF7A4A1E));
    r(0.10, 0.76, 0.80, 0.05, const Color(0xFF5A3010)); // belt
    r(0.38, 0.76, 0.24, 0.05, const Color(0xFFAA7733)); // belt buckle
    // Leg split
    r(0.47, 0.84, 0.06, 0.16, const Color(0xFF5A3010));

    // === LEGS ===
    final double leftY = walking && fr == 0 ? 0.04 : 0.0;
    final double rightY = walking && fr == 1 ? 0.04 : 0.0;

    r(0.10, 1.0 + leftY, 0.37, 0.22, const Color(0xFF6A3A12));
    r(0.53, 1.0 + rightY, 0.37, 0.22, const Color(0xFF6A3A12));

    // === SHOES ===
    r(0.05, 1.18 + leftY, 0.44, 0.09, const Color(0xFF2A1A0A));
    r(0.51, 1.18 + rightY, 0.44, 0.09, const Color(0xFF2A1A0A));
    // Shoe highlight
    r(0.07, 1.18 + leftY, 0.18, 0.04, const Color(0xFF4A3020));
    r(0.53, 1.18 + rightY, 0.18, 0.04, const Color(0xFF4A3020));

    canvas.restore();
  }
}

// ─── Screen Widget ────────────────────────────────────────────────────────────

class MarioGameScreen extends StatefulWidget {
  const MarioGameScreen({super.key});

  @override
  State<MarioGameScreen> createState() => _MarioGameScreenState();
}

class _MarioGameScreenState extends State<MarioGameScreen>
    with TickerProviderStateMixin {
  late Ticker _ticker;
  late _GameState _game;
  Duration _lastTime = Duration.zero;
  double _animTime = 0;

  bool _leftDown = false;
  bool _rightDown = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _game = _GameState();
    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration elapsed) {
    if (_lastTime == Duration.zero) {
      _lastTime = elapsed;
      return;
    }
    final dt = ((elapsed - _lastTime).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastTime = elapsed;
    setState(() {
      _animTime += dt;
      _game.update(dt, _leftDown, _rightDown);
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _restart() => setState(() => _game = _GameState());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Game canvas
          Positioned.fill(
            child: CustomPaint(
              painter: _GamePainter(_game, _animTime),
            ),
          ),
          // HUD
          _buildHUD(),
          // Controls (only while playing or dying)
          if (_game.phase == _Phase.playing || _game.phase == _Phase.dying)
            _buildControls(),
          // Overlay screens
          if (_game.phase != _Phase.playing && _game.phase != _Phase.dying)
            _buildOverlay(),
        ],
      ),
    );
  }

  Widget _buildHUD() {
    final pl = _game.player;
    return Positioned(
      top: 6,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _hud('SCORE', '${pl.score}'),
          const SizedBox(width: 20),
          _hud('COINS', '×${pl.coins}'),
          const SizedBox(width: 20),
          _hud('LIVES', '×${pl.lives}'),
        ],
      ),
    );
  }

  Widget _hud(String label, String val) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontFamily: 'monospace',
                  letterSpacing: 1)),
          Text(val,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, offset: Offset(1, 1))])),
        ],
      );

  Widget _buildControls() {
    return Positioned.fill(
      child: Stack(
        children: [
          // Left/Right D-pad (bottom-left)
          Positioned(
            left: 16,
            bottom: 24,
            child: Row(
              children: [
                _dpadBtn('◀', onDown: () => setState(() => _leftDown = true),
                    onUp: () => setState(() => _leftDown = false)),
                const SizedBox(width: 10),
                _dpadBtn('▶', onDown: () => setState(() => _rightDown = true),
                    onUp: () => setState(() => _rightDown = false)),
              ],
            ),
          ),
          // Jump button (bottom-right)
          Positioned(
            right: 24,
            bottom: 20,
            child: _jumpBtn(),
          ),
        ],
      ),
    );
  }

  Widget _dpadBtn(String icon,
      {required VoidCallback onDown, required VoidCallback onUp}) {
    return GestureDetector(
      onTapDown: (_) => onDown(),
      onTapUp: (_) => onUp(),
      onTapCancel: onUp,
      onPanEnd: (_) => onUp(),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.45), width: 2),
        ),
        child: Center(
          child: Text(icon,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _jumpBtn() {
    return GestureDetector(
      onTapDown: (_) => _game.triggerJump(),
      onTap: () {},
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.65),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 2.5),
          boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 12)],
        ),
        child: const Center(
          child: Text('A',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black54, offset: Offset(1, 1))])),
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    final isWon = _game.phase == _Phase.won;
    final title = isWon ? 'GOAL!' : 'GAME OVER';
    final titleColor = isWon ? const Color(0xFFFFDD00) : Colors.red;

    return Container(
      color: Colors.black.withOpacity(0.65),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: TextStyle(
                    color: titleColor,
                    fontSize: 42,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    shadows: const [
                      Shadow(color: Colors.black, offset: Offset(3, 3))
                    ])),
            if (isWon) ...[
              const SizedBox(height: 8),
              Text('SCORE: ${_game.player.score}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontFamily: 'monospace')),
              Text('COINS: ×${_game.player.coins}',
                  style: const TextStyle(
                      color: Color(0xFFFFCC00),
                      fontSize: 18,
                      fontFamily: 'monospace')),
            ],
            const SizedBox(height: 28),
            GestureDetector(
              onTap: _restart,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF22AA22),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(2, 2))
                  ],
                ),
                child: Text(
                  isWon ? 'PLAY AGAIN' : 'RETRY',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Text('← Back',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontFamily: 'monospace')),
            ),
          ],
        ),
      ),
    );
  }
}
