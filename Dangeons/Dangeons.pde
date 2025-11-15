import java.util.*;

final int COLS = 80;
final int ROWS = 45;
final int TILE = 16;
int scene = 0;
boolean sceneInitialize = false;

Tile[][] map = new Tile[COLS][ROWS];
ArrayList<Room> rooms = new ArrayList<>();
Random rng = new Random();
long seed = System.currentTimeMillis();

int playerX, playerY;
int fovRadius = 8;

void settings() {
  size(COLS * TILE, ROWS * TILE);
  noSmooth();
}

void setup() {
  generate(seed);
}

void draw() {
  switch (scene) {
    case 0:
      if(!sceneInitialize) {
        initTitle();
        sceneInitialize = true;
      }
      drawTitle();
      break;
    case 1:
      if(!sceneInitialize) {
        initGame();
        sceneInitialize = true;
      }
      drawGame();
      break;
    default :
      break;	
  }
}


void keyPressed() {
  int dx = 0, dy = 0;
  if (keyCode == LEFT) dx = -1;
  else if (keyCode == RIGHT) dx = 1;
  else if (keyCode == UP) dy = -1;
  else if (keyCode == DOWN) dy = 1;

  if (dx != 0 || dy != 0) {
    int nx = playerX + dx, ny = playerY + dy;
    if (inBounds(nx, ny) && map[nx][ny].walkable) {
      playerX = nx;
      playerY = ny;
      computeFOV();
    }
  }

  if (key == 'R' || key == 'r') {
    generate(seed); // 同じseedでもう一度
  } else if (key == 'S' || key == 's') {
    seed = System.currentTimeMillis();
    generate(seed);
  } 
}

void changeScene(int next) {
  scene = next;
  sceneInitialize = false; //次のシーンに再初期化する
}

void initTitle() {
  println("タイトル初期化");
}

void initGame() {
  println("ゲーム初期化");
}

void drawTitle() {
  background(255);
  text("Ryunen Bizzare Dangeons, Rescue Squad of Tani", 100, 100);
  if (keyPressed && key == 'n' || keyPressed && key == 'N') {
    changeScene(1);
  }
}

void drawGame() {
    background(10);
    drawMap();
    drawPlayer();
    fill(255);
    text("Seed: " + seed + "  [R]=regenerate  [S]=new seed", 8, 16);
}

// ====== 生成 ======
void generate(long s) {
  rng = new Random(s);
  rooms.clear();
  for (int x=0; x<COLS; x++) for (int y=0; y<ROWS; y++) map[x][y] = new Tile(false);

  // 1) 部屋を置く
  int roomAttempts = 120;
  int minW=4, maxW=10, minH=4, maxH=8;
  for (int i=0; i<roomAttempts; i++) {
    int w = rnd(minW, maxW);
    int h = rnd(minH, maxH);
    int x = rnd(1, COLS - w - 2);
    int y = rnd(1, ROWS - h - 2);
    Room candidate = new Room(x, y, w, h);
    boolean overlaps = false;
    for (Room r : rooms) {
      if (candidate.overlaps(r)) {
        overlaps = true;
        break;
      }
    }
    if (!overlaps) {
      rooms.add(candidate);
      carveRoom(candidate);
    }
  }

  // 2) 部屋の中心を通路で接続（x→yの“L字”でシンプルに）
  //    少なくとも連結になるよう、中心のxでソート→隣同士を繋ぐ
  Collections.sort(rooms, (a, b) -> a.cx() - b.cx());
  for (int i=1; i<rooms.size(); i++) {
    Room a = rooms.get(i-1);
    Room b = rooms.get(i);
    carveCorridor(a.cx(), a.cy(), b.cx(), b.cy());
  }

  // 3) プレイヤー初期位置＝最初の部屋の中心
  if (rooms.size() > 0) {
    playerX = rooms.get(0).cx();
    playerY = rooms.get(0).cy();
  } else {
    playerX = COLS/2;
    playerY = ROWS/2;
  }

  // 4) FOV初期計算
  for (int x=0; x<COLS; x++) for (int y=0; y<ROWS; y++) {
    map[x][y].seen=false;
    map[x][y].visible=false;
  }
  computeFOV();
}

void carveRoom(Room r) {
  for (int x=r.x; x<r.x+r.w; x++) {
    for (int y=r.y; y<r.y+r.h; y++) {
      map[x][y].walkable = true;
    }
  }
}

void carveCorridor(int x1, int y1, int x2, int y2) {
  // L字：まずx方向、次にy方向
  int x = x1, y = y1;
  int sx = (x2 > x1) ? 1 : -1;
  while (x != x2) {
    map[x][y].walkable = true;
    x += sx;
  }
  int sy = (y2 > y1) ? 1 : -1;
  while (y != y2) {
    map[x][y].walkable = true;
    y += sy;
  }
  map[x][y].walkable = true;
}

int rnd(int a, int b) { // inclusive
  return a + rng.nextInt(b - a + 1);
}

boolean inBounds(int x, int y) {
  return x>=0 && x<COLS && y>=0 && y<ROWS;
}

// ====== FOV（簡易ブレゼンハムLOSの全方向キャスト）======
void computeFOV() {
  // 可視/不可視を初期化
  for (int x=0; x<COLS; x++) for (int y=0; y<ROWS; y++) map[x][y].visible=false;

  for (int dy=-fovRadius; dy<=fovRadius; dy++) {
    for (int dx=-fovRadius; dx<=fovRadius; dx++) {
      int tx = playerX + dx;
      int ty = playerY + dy;
      if (!inBounds(tx, ty)) continue;
      if (dx*dx + dy*dy > fovRadius * fovRadius) continue;
      if (los(playerX, playerY, tx, ty)) {
        map[tx][ty].visible = true;
        map[tx][ty].seen = true;
      }
    }
  }
}

// line of sight: 壁タイルは視界ブロック。歩行可能タイルのみ透過。
boolean los(int x0, int y0, int x1, int y1) {
  int dx = abs(x1 - x0), sx = x0 < x1 ? 1 : -1;
  int dy = -abs(y1 - y0), sy = y0 < y1 ? 1 : -1;
  int err = dx + dy, e2;
  int x = x0, y = y0;

  while (true) {
    if (!(x == x0 && y == y0)) { // 始点はスキップ
      if (!inBounds(x, y)) return false;
      if (!map[x][y].walkable) return false; // 壁でブロック
    }
    if (x == x1 && y == y1) return true;
    e2 = 2 * err;
    if (e2 >= dy) {
      err += dy;
      x += sx;
    }
    if (e2 <= dx) {
      err += dx;
      y += sy;
    }
  }
}

// ====== 描画 ======
void drawMap() {
  for (int x=0; x<COLS; x++) {
    for (int y=0; y<ROWS; y++) {
      Tile t = map[x][y];
      int px = x * TILE, py = y * TILE;
      if (t.visible) {
        if (t.walkable) fill(210, 220, 230);
        else fill(40);
      } else if (t.seen) {
        if (t.walkable) fill(120, 130, 140);
        else fill(25);
      } else {
        fill(10);
      }
      noStroke();
      rect(px, py, TILE, TILE);
    }
  }
}

void drawPlayer() {
  fill(255, 120, 60);
  noStroke();
  rect(playerX*TILE, playerY*TILE, TILE, TILE);
}

// ====== 型 ======
class Tile {
  boolean walkable;
  boolean seen = false;
  boolean visible = false;
  Tile(boolean walkable) {
    this.walkable = walkable;
  }
}

class Room {
  int x, y, w, h;
  Room(int x, int y, int w, int h) {
    this.x=x;
    this.y=y;
    this.w=w;
    this.h=h;
  }
  boolean overlaps(Room o) {
    return !(x+w+1 <= o.x || o.x+o.w+1 <= x || y+h+1 <= o.y || o.y+o.h+1 <= y);
  }
  int cx() {
    return x + w/2;
  }
  int cy() {
    return y + h/2;
  }
}
