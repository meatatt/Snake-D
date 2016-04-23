//Written by Sheldon Shen, aka meatatt, 2016-04-22
//See the included license.txt for copyright and license.

module snake;

import std.concurrency,std.container.dlist,std.random,std.conv,std.datetime: msecs;
import clibase;

enum InitDirection=Direction.down;

enum SnakeChar:uint{head='@',tail='#',cell='%',food='¥'}
enum TableChar:uint{
	top='═',top_mid='╤',top_left='╔',top_right='╗',
	bottom='═',bottom_mid='╧',bottom_left='╚',bottom_right='╝',
	left='║',left_mid='╟',
	mid='─',mid_mid='┼',
	right='║',right_mid='╢',middle='│'
}

enum SnakeColor{
	box=Color.cyan | Attribute.bold,
	food=Color.yellow,
	being=Color.green,
	bg=Color.black
}

enum Status{alive,dead,succeed}

enum Timeout=600.msecs;

class Snake{
	this(size_t space,Position entry){
		_space=space;
		_length=1;
		_curDir=InitDirection;
		flesh.insert(entry);
		addLocalBuf(flesh.front,SnakeChar.head,SnakeColor.being);
	}
	Status status(){return _status;}
	size_t length(){return _length;}
	Direction curDir(){return _curDir;}
	void move(Direction dir){
		assert (_status==Status.alive);
		if (_curDir==dir.reverse)
			return;
		else
			_curDir=dir;
		Position newHead=flesh.front.to(dir);
		if (scrLookup(newHead).ch==BlankCell.ch){
			addLocalBuf(flesh.back,BlankCell);
			flesh.removeBack();
		}
		else if (scrLookup(newHead).ch==SnakeChar.food) ++_length;
		else{
			_status=Status.dead;
			return;
		}
		if (!flesh.empty){
			addLocalBuf(flesh.front,SnakeChar.cell,SnakeColor.being);
			addLocalBuf(flesh.back,SnakeChar.tail,SnakeColor.being);
		}
		addLocalBuf(newHead,SnakeChar.head,SnakeColor.being);
		flesh.insertFront(newHead);
		if (_length==_space)
			_status=Status.succeed;
	}
private:
	Direction _curDir;
	Status _status;
	size_t _length;
	immutable size_t _space;
	DList!Position flesh;
	//SnakeBox _room;
}

class SnakeBox{
	this(Position startPoint,Size size_f){
		_shape=PRange(startPoint,size_f);
		_space=(size_f.width-1)*(size_f.height-1);
		drawBox();
		updateScr();
	}
	size_t space(){return _space;}
	Position entry(){return Position(_shape.xl+1,_shape.yt+1);}
	void startGame(){
		_timeLoopTid=spawn(&_timeLoop,space,entry,_shape.innerRange);
		_timeLoopTidString=_timeLoopTid.to!string;
		register(_timeLoopTidString,_timeLoopTid);
	}
	Tid timeLoopTid(){return _timeLoopTid;}
	bool isRunning(){
		return _timeLoopTidString!is null&&
			locate(_timeLoopTidString)==_timeLoopTid;
	}
	struct TermSignal{}
	enum termSignal=TermSignal.init;
private:
	size_t _space;
	PRange _shape;
	Tid _timeLoopTid;
	string _timeLoopTidString;
	void drawBox(){
		addLocalBuf(_shape.topLeft,TableChar.top_left,SnakeColor.box);
		addLocalBuf(_shape.topRight,TableChar.top_right,SnakeColor.box);
		addLocalBuf(_shape.bottomLeft,TableChar.bottom_left,SnakeColor.box);
		addLocalBuf(_shape.bottomRight,TableChar.bottom_right,SnakeColor.box);
		setRange(LineY(_shape.xl,_shape.yt+1,_shape.yb)[],TableChar.left,SnakeColor.box);
		setRange(LineY(_shape.xr,_shape.yt+1,_shape.yb)[],TableChar.right,SnakeColor.box);
		setRange(LineX(_shape.yt,_shape.xl+1,_shape.xr)[],TableChar.top,SnakeColor.box);
		setRange(LineX(_shape.yb,_shape.xl+1,_shape.xr)[],TableChar.bottom,SnakeColor.box);
	}
	static void _timeLoop(size_t space_f,Position entry_f,PRange pRange){
		Snake soul=new Snake(space_f,entry_f);
		updateScr();
		Position food;
		void refreshFood(){
			do food=Position(uniform(pRange.xl,pRange.xr),
				uniform(pRange.yt,pRange.yb));
			while (scrLookup(food).ch!=BlankCell.ch);
			addLocalBuf(food,SnakeChar.food,SnakeColor.food);
			updateScr();
		}
		bool keepRunning=true;
		while (keepRunning&&soul.status==Status.alive){
			if (scrLookup(food).ch!=SnakeChar.food)
				refreshFood();
			if (!receiveTimeout(Timeout,
					(Direction dir){soul.move(dir);},
					(TermSignal t){keepRunning=false;}))
				soul.move(soul.curDir);
			updateScr();
		}
		if (soul.status==Status.dead)
			foreach(int i,c;"Dead!")
				addLocalBuf(i,0,c);
		else if (keepRunning)
			foreach(int i,c;"Success!")
				addLocalBuf(i,0,c);
		else
			foreach(int i,c;"Terminated.")
				addLocalBuf(i,0,c);
		updateScr();
	}
}