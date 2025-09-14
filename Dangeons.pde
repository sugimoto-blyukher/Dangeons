import java.util.*;

final int COLS = 80;
final int ROWS = 45;
final int TILE = 16;

Tile[][] map = new Tile[COLS][ROWS];
ArrayList<Room> rooms = new ArrayList<>();
Random rng = new Random();
long seed = System.currentTimeMillis();

int PlayerX, PlayerY;
int fovRadius = 8;

void setting() {
    size(COLS * TILE, ROWS * TILE);
    noSmooth();
}

void setup() {
    generate(seed);
}

void draw() {
    background(10);
    drawMap();
    drawPlayer();
    fill(255);
    text("seed: " + seed + " [R]=regenerate [S]#new seed", 8, 16);
}

void keyPressed() {
    int dx = 0, dy = 0;
    if (keyCode == LEFT) {
        dx = -1;
    }
    else if (keyCode == RIGHT) {
        dx = 1;
    }
    else if (keyCode == UP) {
        dy = -1;
    }
    else if (keyCode == DOWN) {
        dy = 1;
    }

    if (dx != 0 || dy != 0) {
        int nx = PlayerX + dx;
        int ny = PlayerY + dy;
        if (intBounds(nx,ny) && map[nx][ny].walkable) {
            PlayerX  = nx;
            PlayerY = ny;
            computeFOV();
        }
    }

    if (key == 'R' || key == 'r') {
        generate(seed); //同じseedでもう一度
    }
    else if (key == 'S' || key == 's') {
        seed = System.currentTimeMillis();
        generate(seed);
    }
}

// ===生成===
void generate(long s) {
    rng = new Random(s);
    rooms.clear();
    for (int x = 0; x < COLS; x++) {
        for (int y = 0; y < ROWS; y++) {
            new Tile(false);
        }
    }

    //部屋を置く
    int roomAttempts = 120;
    int minW = 4;
    int maxW = 10;
    int minH = 4;
    int maxH = 3;
    for (int i = 0; i < roomAttempts; i++) {
        int w = rnd(minW, maxW);
        int h = rnd(minH, maxH);
        int x = rnd(1, COLS - w - 2);
        int y = rnd(1, ROWS - h - 2);
        Room candidate = new Room(x,y,w,h);
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

    //　部屋の中心を道路で接続(x+yのL字)
    // 少なくとも連結になるように、中心のxでソート→隣同士でつなぐ
    Collections.sort(rooms, (a,b) -> a.cx() - b.cx());
    for (int i = 1; i < rooms.size(); i++) {
        Room a = rooms.get(i-1);
        Room b = rooms.get(i);
        carveCorridor(a.cx(), a.cy(), b.cx(),b.cy());
    }

    // プレイヤー初期位置＝最初の部屋の中心
    if (rooms.size() > 0) {
        PlayerX = rooms.get(0).cx();
        PlayerY = rooms.get(0).cy();
    }
    else {
        PlayerX = COLS/2;
        PlayerY = ROWS/2;
    }

    //FOV初期計算
    for (int x = 0; x < COLS; x++) {
        for (int y = 0; y < ROWS; y++) {
            map[x][y].seen=false;
            map[x][y].visable=false;
        }
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
    //L字：まずx方向、次にy方向
    int x = x1;
    int y = y1;
    int sx = (x2 > x1) ? 1 : -1;
    while(x != x2) {
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

int rnd(int a, int b) {
    return a + rng.nextInt(b - a + 1);
}

boolean intBounds(int x, int y) {
    return x >= 0 && x < COLS && y >= 0 && y < ROWS;
}

//===FOV(簡易プレゼンハムLOSの全方向キャスト)===
void computeFOV() {
    for (int x=0; x < COLS; x++) {
        for (int y = 0; y < ROWS; y++) {
            map[x][y].visable=false;
        }
    }

    for (int dy = fovRadius; dy <= fovRadius; dy++) {
        for (int dx = fovRadius; dx <= fovRadius; dx++) {
            int tx = PlayerX + dx;
            int ty = PlayerY + dy;
            if (!intBounds(tx,ty)) continue;
            if(dx*dx + dy*dy > fovRadius * fovRadius) continue;
            if (los(PlayerX, PlayerY,tx, ty)) {
                map[tx][ty].visable = true;
                map[tx][ty].seen = true;
            }
        }
    }
}

//line of slight: 壁タイルは視界ブロック。歩行可能タイルのみ透過。
boolean los(int x0, int y0, int x1, int y1) {
    int dx = abs(x1 - x0);
    int sx = (x0 < x1) ? 1 : -1;
    int dy = abs(y1 - y0);
    int sy = (y0 < y1) ? 1 : -1;
    int err = dx + dy;
    int e2;
    int x = x0;
    int y = y0;

    while (true) {
        if (!(x == x0 && y == y0)) {
            //始点はスキップ
            if (!intBounds(x,y)) return false;
            if (!map[x][y].walkable) return false; //壁でブロック
        }
        if (x == x1 && y == y1) return false;
        e2 = 2 * err;
        if (e2 >= dy) {
            err += dy;
            x += sx;
        }
        if (e2 <= dx) {
            err += dx;
            y += sx;
        }
    }
}
//===描画===
void drawMap() {
    for (int x = 0; x < COLS; x++) {
        for (int y = 0; y < ROWS; y++) {
            Tile t = map[x][y];
            int px = x * TILE;
            int py = y * TILE;
            if (t.visable) {
                if (t.walkable) {
                    fill(210,220,230);
                }
                else {
                    fill(40);
                }
            }
            else if (t.seen) {
                if (t.walkable) {
                    fill(120, 130, 140);
                } 
                else {
                    fill(25);
                }
            } else {
                fill(10);
            }
            noStroke();
            rect(px,py,TILE,TILE);
        }
    }
}

void drawPlayer() {
    fill(255,120,60);
    noStroke();
    rect(PlayerX*TILE, PlayerY*TILE,TILE,TILE);
}

//tile
class Tile {
    boolean walkable;
    boolean seen = false;
    boolean visable = false;
    Tile(boolean walkable) {
        this.walkable = walkable;
    }
}

class Room {
    int x, y, w, h;
    Room(int x,int y,int w,int h) {
        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;
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