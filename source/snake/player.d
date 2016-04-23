module player;

import std.concurrency: send;

import termbox:Event,pollEvent,Key;

import snake,clibase;

void manual(SnakeBox box){
	Event e;
	do{
		pollEvent(&e);
		switch (e.key){
			case Key.arrowUp: send(box.timeLoopTid,Direction.up);
				break;
			case Key.arrowDown: send(box.timeLoopTid,Direction.down);
				break;
			case Key.arrowRight: send(box.timeLoopTid,Direction.right);
				break;
			case Key.arrowLeft: send(box.timeLoopTid,Direction.left);
				break;
			case Key.esc: send(box.timeLoopTid,box.termSignal);
				break;
			default: break;
		}
	}while(box.isRunning);
}

void ai(SnakeBox box,bool function(PRange,out Direction) getMove){
	Direction dir;
	do{
		waitForScrRefresh();
		if (getMove(box.shape.innerRange,dir))
			send(box.timeLoopTid,dir);
		else
			send(box.timeLoopTid,box.termSignal);
	}while (box.isRunning);
	pause();
}

bool direct(PRange pRange,out Direction dir){
	Position head=findCh(SnakeChar.head,pRange),food=findCh(SnakeChar.food,pRange);
	assert (head!=food);
	int dx=food.x-head.x,dy=food.y-head.y;
	assert (dx||dy);
	Direction[] dirs;
	if (dx!=0){
		if (dx>0)
			dirs~=Direction.right;
		else// if (dx<0)
			dirs~=Direction.left;
	}
	if (dy!=0){
		if (dy>0)
			dirs~=Direction.down;
		else// if (dy<0)
			dirs~=Direction.up;
	}
	foreach (dir_t;dirs)
		if (scrLookup(head.to(dir_t)).ch==BlankCell.ch||
			scrLookup(head.to(dir_t)).ch==SnakeChar.food){
		dir=dir_t;
		return true;
	}
	return false;
}

private:
void waitForScrRefresh(){
	import core.thread;
	static const(Cell[])* cache;
	while (cache is scrMirror.ptr)
		Thread.sleep(1.msecs);
	cache=scrMirror().ptr;
}
Position findCh(uint ch,PRange pRange){
	do{
		import std.algorithm: find;
		foreach (yi;pRange.yt..pRange.yb){
			auto t=find!"a.ch==b"(scrMirror[yi][pRange.xl..pRange.xr],ch);
			if (t.length!=0)
				return Position(cast(uint)(pRange.xr-t.length),yi);
		}
		waitForScrRefresh();
	}while(true);
}
void pause(){
	pollEvent(new Event);
}