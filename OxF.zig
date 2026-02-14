const std = @import("std");

pub fn ansiCode(comptime code: []const u8) []const u8 {
  
  return "\x1b["++code;
}

var bufferWriter = std.io.bufferedWriter(std.io.getStdOut().writer());
const writer = bufferWriter.writer();
const reader = std.io.getStdIn().reader();
var rand:std.Random = undefined;

pub fn moveCursor(x:i16,y:i16) void{
  var ansi = [_]u8{0} ** 16;
  _ = std.fmt.bufPrint(&ansi,"\x1b[{d};{d}H",.{y,x}) catch unreachable;
  writer.writeAll(&ansi) catch unreachable;
}
pub fn printAt(x:i16,y:i16,string:[]const u8) void{
  moveCursor(x,y);
  writer.writeAll(string) catch unreachable;
}

const Keys = enum{
  none,
  q,
  r,
  up,
  down,
  left,
  right
};

pub fn readInput() Keys{
  var buffer = [_]u8{0} ** 6;

  var key:Keys = Keys.none;

  var char:u8 = 0;
  
  //Wait until key press
  while (char==0)
    char = reader.readByte() catch 0;
    
  var i:u8 = 0;
  while (char!=0){
    if (i>3)
      return Keys.none;
    buffer[i] = char;
    char = reader.readByte() catch 0;
    i+=1;
  }
  
  key = switch(buffer[0]){
    'q' => Keys.q,
    'r' => Keys.r,
    27  => switch(buffer[2]){
      'A' => Keys.up,
      'B' => Keys.down,
      'C' => Keys.left,
      'D' => Keys.right,
      else => Keys.none
    },
    else => Keys.none
  };
  return key;
}

pub fn numberCollide(grid:[]u8,index1:u8,index2:u8) void{
  const number1 = grid[index1];
  const number2 = grid[index2];

  if (number1==number2){
    grid[index1] = 0xff;
    grid[index2] += 1;
  }
}

pub fn clearScreen() void{
  const clear = comptime ansiCode("2;2H")++ansiCode("2J")++ansiCode("3J");
  writer.writeAll(clear) catch unreachable;
  bufferWriter.flush() catch unreachable;
}

pub fn moveGrid(grid:[]u8,x:i8,y:i8) void{
  var j:u8 = 0;
  while(j<2):(j+=1){
    if (x==0){
      if (y==1){
        var i:u8 = 0;
        while(i<6):(i+=1) {
          const number = grid[i];
          if (number==0xff) continue;
          if (grid[i+3]!=0xff ) {
            numberCollide(grid,i,i+3);
            continue;
          }
          grid[i+3] = number;
          grid[i] = 0xff;
        }
      }
      if (y==-1){
        var i:u8 = 8;
        while(i>=3):(i-=1) {
          const number = grid[i];
          if (number==0xff) continue;
          if (grid[i-3]!=0xff ) {
            numberCollide(grid,i,i-3);
            continue;
          }
          grid[i-3] = number;
          grid[i] = 0xff;
        }
      }
    } else if (y==0){
      if (x==1){
        var i:u8 = 0;
        while(i<9):(i+=1) {
          const number = grid[i];
          if (number==0xff or i%3==2) continue;
          if (grid[i+1]!=0xff ) {
            numberCollide(grid,i,i+1);
            continue;
          }
          grid[i+1] = number;
          grid[i] = 0xff;
        }
      }
      if (x==-1){
        var i:u8 = 8;
        while(i>0):(i-=1) {
          const number = grid[i];
          if (number==0xff or i%3==0) continue;
          if (grid[i-1]!=0xff ) {
            numberCollide(grid,i,i-1);
            continue;
          }
          grid[i-1] = number;
          grid[i] = 0xff;
        }
      }
    }
  }
}

pub fn printGrid(grid:[]const u8) void {
  const black = ansiCode("m");
  const white = ansiCode("7m");
  
  var buffer = [_]u8{0} ** 9;
  std.mem.copyForwards(u8,&buffer,grid);
  
  for (buffer,0..) |number,i| { 
    if(number != 0xff)
      buffer[i] = if (number==4) 'f' else std.math.pow(u8,2,number) + '0';
  }

  clearScreen();
  
  writer.writeAll(white) catch unreachable;
  for (buffer,0..) |number,i| { 
    if(number!=0xff)
      printAt(@intCast((i%3)+2),@intCast(@divTrunc(i,3)+2),buffer[i..i+1]);
  }
  
  writer.writeAll(black) catch unreachable;
  bufferWriter.flush() catch unreachable;
}

pub fn gameStart() void {
  var grid = [_]u8{0xff} ** 9;
  
  grid[rand.intRangeAtMost(u8,0,8)] = 0;
  
  var keyPressed = Keys.none;
  while(true){

    // Check if the grid is full
    
    var isFull = true;
    var won    = false;
    for (grid) |number| {
      if (number==0xff){
        isFull = false;
      }
      if (number==5){
        won = true;
        break;
      }
      
    }

    if (won or isFull){
      clearScreen();
      writer.writeAll(if (won) "You won!" else "Game over...") catch unreachable;
      bufferWriter.flush() catch unreachable;
      
      _ = readInput();
      return;
    }
    
    var i = rand.intRangeAtMost(u8,0,8);
    while (grid[i]!=0xff) 
      i = rand.intRangeAtMost(u8,0,8);
    
    grid[i] = 0;
    
    
    printGrid(&grid);
    
    moveCursor(1,1);
    bufferWriter.flush() catch unreachable;

    keyPressed = readInput();
    
    if(keyPressed==Keys.q)
      return;
      
    const x:i8 = switch(keyPressed){
      Keys.left => 1,
      Keys.right => -1,
      else => 0
    };
    const y:i8 = switch(keyPressed){
      Keys.down => 1,
      Keys.up => -1,
      else => 0
    };
    
    moveGrid(&grid,x,y);
  }
}

pub fn main() void {
  // Set up random
  const seed:u64 = @intCast(std.time.timestamp());
  var xo256:std.Random.Xoshiro256 = .init(seed);
  rand = xo256.random();
  
  // Set up term
  writer.writeAll(ansiCode("?1049h")) catch unreachable;

  clearScreen();

  var oldTermios:std.c.termios = undefined;
  var rawTermios:std.c.termios = std.mem.zeroes(std.c.termios);
  
  rawTermios.oflag.OPOST = true;
  rawTermios.oflag.ONLCR = true;
  
  const fd:i32 = std.io.getStdOut().handle;
  _ = std.c.tcgetattr(fd,&oldTermios);
  _ = std.c.tcsetattr(fd,std.c.TCSA.NOW,&rawTermios);

  //Clean up
  defer{
    writer.writeAll(ansiCode("?1049l")) catch unreachable;
    bufferWriter.flush() catch unreachable;
    
    _ = std.c.tcsetattr(fd,std.c.TCSA.NOW,&oldTermios);
  }
  
  gameStart();
}
