package jsonmod;

enum EncodeStyle 
{
	Simple;
	Fancy;
	Indented;
	Custom(style:IEncodeStyle);
}