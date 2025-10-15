ELK Parser Generator / MaKro 09.95

Edit.Open Expr.ELK	Edit.Open ELK.ELK
Edit.Open OberonR.ELK	Edit.Open Oberon.ELK
Edit.Open Modula2R.ELK	Edit.Open Modula2.ELK

ELK.Generate * !/i	Compiler.Compile Parser.Mod /s ~
Parser.Parse *	Edit.Open Parser.Mod

Edit.Open ELK.Mod	Edit.Open Sets.Mod
Edit.Open Scanner.Mod	Edit.Open Parser.Fix

System.Free Parser Scanner ~
System.DeleteFiles
  Parser.Mod
  Parser.Mod.Bak
  Parser.Sym
  Parser.Obj
  Parser.Tab ~
