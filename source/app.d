//Written by Sheldon Shen, aka meatatt, 2016-04-23
//See the included LICENSE for copyright and license.

import std.concurrency: send;
import std.conv: to;

import termbox:Event,pollEvent,Key;

import snake,clibase;

void main(string[] args){
	scrInit();
	scope (exit) scrQuit();
	Size boxSize;
	if (args.length>=3)
		boxSize=Size(args[1].to!uint,args[2].to!uint);
	else
		boxSize=Size(width()-1,height()-1);
	auto box=new SnakeBox(Position((width()-boxSize.width)/2,(height()-boxSize.height)/2),
		boxSize);
	box.startGame();
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
