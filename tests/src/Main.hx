class Main
{
    static function main()
    {
        var r = new haxe.unit.TestRunner();
        r.add(new BaseTests());
        r.add(new ExtTests());
        r.run();
    }
}