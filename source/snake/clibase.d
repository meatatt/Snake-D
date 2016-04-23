//Written by Sheldon Shen, aka meatatt, 2016-04-23
//See the included LICENSE for copyright and license.

module clibase;

import core.sync.mutex: Mutex;

import std.algorithm: map;
import std.array: array;
import std.container.dlist: DList;
import std.range.primitives: isInputRange,ElementType;

import termbox;
public import termbox: Cell,Color,Attribute,height,width;

shared static this(){
	mutex=new Mutex();
}

void scrInit(){
	init();
	refetchBuf();
}
void scrQuit(){
	scrBuf=null;
	clrLocalBuf();
	shutdown();
}

enum BlankCell=Cell(32,0,0);

enum Direction{up,down,left,right}
@property Direction reverse(Direction dir){
	with(Direction)final switch (dir){
		case down: return up;
		case up: return down;
		case left: return right;
		case right: return left;
	}
}
struct Position{
	int x,y;
	Position to(Direction dir){
		with(Direction)final switch (dir){
			case down: return Position(x,y+1);
			case up: return Position(x,y-1);
			case left: return Position(x-1,y);
			case right: return Position(x+1,y);
		}
	}
}
struct Size{
	uint width,height;
}
struct PRange{
	uint xl,xr,yt,yb;
	this(uint xl_f,uint xr_f,uint yt_f,uint yb_f){
		xl=xl_f;xr=xr_f;yt=yt_f;yb=yb_f;
	}
	this(Position topLeft,Size size){
		xl=topLeft.x;
		xr=xl+size.width;
		yt=topLeft.y;
		yb=yt+size.height;
	}
	Position topLeft(){return Position(xl,yt);}
	Position topRight(){return Position(xr,yt);}
	Position bottomLeft(){return Position(xl,yb);}
	Position bottomRight(){return Position(xr,yb);}
	PRange innerRange(){
		return PRange(xl+1,xr,yt+1,yb);
	}
}
enum LineType{x,y}
struct Line(LineType type){
	this(uint d,uint s,uint e){
		_range=Range(d,s,e);
	}
	static struct Range{
		bool empty(){return _s==_e;}
		void popFront(){++_s;}
		Position front(){
			static if (type==LineType.x)
				return Position(_s,_d);
			else
				return Position(_d,_s);
		}
	private:
		uint _d,_s,_e;
	}
	Range opSlice(){return _range;}
private:
	Range _range;
}
alias LineX=Line!(LineType.x);
alias LineY=Line!(LineType.y);

struct PCell{
	Position pos;
	Cell cell;
	this(in Position pos_f,in Cell cell_f){
		pos=pos_f;
		cell=cell_f;
	}
	this(in Position pos_f,in uint ch,in ushort fg=0,in ushort bg=0){
		pos=pos_f;
		cell=Cell(ch,fg,bg);
	}
	this(in int x,in int y,in uint ch,in ushort fg=0,in ushort bg=0){
		pos=Position(x,y);
		cell=Cell(ch,fg,bg);
	}
}

const(Cell[][]) scrTable(){
		return scrBuf;
}
Cell scrLookup(Position pos){
	return scrBuf[pos.y][pos.x];
}

alias DList!PCell CellBuf;
CellBuf threadLocalBuf=CellBuf();
void addLocalBuf(in int x,in int y,in uint ch,in ushort fg=BlankCell.fg,in ushort bg=BlankCell.bg){
	threadLocalBuf.stableInsert(PCell(Position(x,y),Cell(ch,fg,bg)));
}
void addLocalBuf(in Position pos,in uint ch,in ushort fg=BlankCell.fg,in ushort bg=BlankCell.bg){
	threadLocalBuf.stableInsert(PCell(pos,Cell(ch,fg,bg)));
}
void addLocalBuf(in Position pos,in Cell cell){
	threadLocalBuf.stableInsert(PCell(pos,cell));
}
void clrLocalBuf(){
	if (!threadLocalBuf.empty())
		threadLocalBuf.clear();
}

void setRange(Range)(Range range,Cell cell=BlankCell)
if (isInputRange!Range&&is(ElementType!Range:Position)){synchronized(mutex){
		applyLocalBuf();
		foreach (Position pos;range)
			setCell(pos,cell);
	}}
void setRange(Range)(Range range,uint ch,ushort fg=BlankCell.fg,ushort bg=BlankCell.bg)
if (isInputRange!Range&&is(ElementType!Range:Position)){synchronized(mutex){
		applyLocalBuf();
		Cell cell=Cell(ch,fg,bg);
		foreach (Position pos;range)
			setCell(pos,cell);
	}}
void updateScr(){synchronized(mutex){
		applyLocalBuf();
		flush();
		refetchBuf();
	}}
void clrScr(){synchronized(mutex){
		clrLocalBuf();
		clear();
		refetchBuf();
	}}

private:
__gshared Mutex mutex;
__gshared Cell[][] scrBuf;
//__gshared immutable(Cell[])[] roScrBuf;
void refetchBuf(){
	Cell* buf=cellBuffer();
	if (scrBuf is null || scrBuf[0].ptr !is buf){
		scrBuf=new Cell[][](height());
		auto cachedW=width();
		foreach (ref line;scrBuf){
			line=buf[0..cachedW];
			buf+=cachedW;
		}
	}
	assert (scrBuf.length==height()&&scrBuf[0].length==width());
	//roScrBuf=scrBuf.map!(a=>a.idup).array;
}
void applyLocalBuf(){
	foreach (c;threadLocalBuf)
		setCell(c.pos,c.cell);
	clrLocalBuf();
}
void setCell(Position pos,Cell cell){
	with (pos) if (x>=0&&y>=0&&x<width()&&y<height())
		scrBuf[y][x]=cell;
}
