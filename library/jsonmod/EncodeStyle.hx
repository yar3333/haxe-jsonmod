package jsonmod;

enum EncodeStyle 
{
	Simple;
	Fancy;
	Custom(style:IEncodeStyle);
}