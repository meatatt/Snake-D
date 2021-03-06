﻿//Written by Sheldon Shen, aka meatatt, 2016-04-23
//See the included LICENSE for copyright and license.

import std.conv: to;

import snake,clibase,player;

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
	manual(box);
	//ai(box,&direct);
}



